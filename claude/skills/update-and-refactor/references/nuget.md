# NuGet (.NET)

## Manifests

- `*.csproj` / `*.fsproj` — `<PackageReference Include="X" Version="1.2.3" />`
- `Directory.Packages.props` — central package management; versions live here as
  `<PackageVersion ... />` and the csproj references omit the version. Check for
  this file first; if it exists, it is the source of truth for versions.
- `packages.config` — legacy; `<package id="X" version="1.2.3" />`

Direct dependencies are those declared in these files. Transitive packages
(dependencies of your dependencies) are not listed here and are out of scope —
don't analyze them unless the user asks.

## Inventory outdated

Restore first (the outdated check needs the assets file), then list:

```bash
dotnet restore
dotnet list package --outdated
```

`--outdated` reports `Requested`, `Resolved`, and `Latest` per package and only
shows ones with a newer version — exactly the inventory you need. By default it
excludes prereleases; keep it that way unless the project is already on a
prerelease (then add `--include-prerelease` for that package's lookup).

To distinguish major/minor/patch, compare `Resolved` to `Latest` semver
components. `dotnet list package --outdated --include-transitive` exists but
keep transitive out of the default inventory.

## Map package → usage in code

NuGet's trap: the package id is not the namespace. `Azure.AI.Agents.Persistent`
exposes types under `Azure.AI.Agents.Persistent` here, but many packages don't
match (e.g. `Microsoft.EntityFrameworkCore` → `Microsoft.EntityFrameworkCore`,
but `Newtonsoft.Json` → `Newtonsoft.Json`, while `Polly` → `Polly` and
`MediatR` → `MediatR`). Don't assume.

To find the namespaces a package actually provides:

1. Inspect the package's public API. The reliable way: look at the installed
   assembly under `~/.nuget/packages/<id-lowercased>/<version>/lib/<tfm>/` and
   read the namespaces, or check the package's docs via Context7 / Microsoft
   Learn MCP.
2. Then grep the codebase for `using <namespace>` and for the concrete type and
   method names. Capture file + line + snippet for each hit.

Record both the import sites and the call sites — the call sites are what a
breaking signature change actually hits.

## Build-verify (ground truth for breaking changes)

This is the most reliable signal. Procedure:

1. Copy the relevant project(s) to the scratchpad — never mutate the user's tree.
   Copy the whole solution if projects reference each other.
2. In the copy, bump the package to `Latest` (edit the csproj or
   `Directory.Packages.props`).
3. `dotnet restore && dotnet build` in the copy.
4. Capture the compiler errors. These are your verified breaking changes.

Map common errors to break types:
- `CS0246` / `CS0234` — type or namespace no longer exists (removed/renamed/moved)
- `CS1061` — member no longer exists on the type (removed/renamed method/prop)
- `CS1503` / `CS1501` — signature changed (params added/removed/retyped)
- `CS0619` / `CS0618` — `[Obsolete]` (warning, or error if treated as error) →
  deprecation, report as behavioral even if it still compiles
- `CS0535` — interface member added you must now implement

Pair each error with the matching usage site from the mapping step so the report
points at the exact line that breaks. A clean build is itself a finding: "No
compile-level breaks; review behavioral notes." It does not rule out runtime
changes — that's what the changelog pass is for.

## Notes

- Multi-targeted projects: build all target frameworks; a break may exist on one
  TFM only.
- `<TreatWarningsAsErrors>` projects will surface obsoletions as build failures —
  useful, but classify them as deprecations, not hard breaks.
- Source generators / analyzers shipped as NuGet packages won't show usage via
  grep; note them as "tooling package, usage not statically locatable."
