# npm (Node / Angular)

## Manifests

- `package.json` — `dependencies` and `devDependencies` are your direct deps.
  Distinguish them in the report; a breaking change in a `devDependency`
  (bundler, test runner) has different blast radius than one in a runtime dep.
- Lockfile (`package-lock.json` / `npm-shrinkwrap.json`) pins resolved versions.

`peerDependencies` are constraints, not installs — don't bump them directly, but
flag if an upgrade would violate one.

## Inventory outdated

```bash
npm outdated
```

Columns: `Current`, `Wanted` (max satisfying the semver range in package.json),
`Latest` (newest published). The gap that matters for this skill is
`Current → Latest`. `Wanted` tells you whether the range already permits the
update (a plain `npm update` would take it) or whether crossing to `Latest`
requires editing the range — usually a major bump. Note which it is per package.

`npm outdated --json` gives a clean machine-readable form if you want to script
the table. Exclude prereleases unless the project is already on one.

## Map package → usage in code

This is the easy ecosystem: the import specifier *is* the package name.

- `import x from 'pkg'` / `import { y } from 'pkg/subpath'`
- `require('pkg')`
- For scoped packages: `'@scope/pkg'`

Grep for `from 'pkg'`, `from "pkg`, and `require('pkg'`. Then locate the actual
API calls on the imported symbols — those are the breakage surface. For Angular,
also check `angular.json`, module imports, and DI providers for the package.

Record file + line + snippet per hit. Zero usage on an outdated dependency →
removal candidate; call it out.

## Build-verify (type-checked breaks)

Plain JavaScript has no compile step, but most of this user's Node/Angular work
is TypeScript, which does. Procedure:

1. Copy the project to the scratchpad (or use a fresh `node_modules` there).
2. Bump the package to `Latest` in the copy's package.json.
3. `npm install` then type-check / build:
   - TypeScript: `npx tsc --noEmit` (fast, no bundling) catches type-level breaks.
   - Angular: `ng build` for a full check, or `npx tsc --noEmit` for speed.
4. Capture the type errors — these are verified breaking changes. Many packages
   ship their own types, so a changed signature surfaces as a `tsc` error
   against your call sites.

For plain-JS projects with no types, you can't get compile-level ground truth.
Say so in the report and lean harder on the changelog plus, if the project has a
fast test suite, a trial `npm test` in the copy.

Map common signals:
- `TS2305` / `TS2724` — export no longer exists (removed/renamed)
- `TS2345` / `TS2554` — argument type / arity changed (signature break)
- `TS2339` — property no longer on type (removed member)
- Deprecations: many packages mark APIs `@deprecated` in JSDoc — surface via
  editor/LSP or changelog, report as behavioral.

## Notes

- ESM vs CJS migrations are a frequent major-version break (package goes
  ESM-only). `tsc` and runtime both reveal it; flag it explicitly because the
  fix is often config-wide, not per-call-site.
- A bumped package may drag peer-dep requirements (e.g. a new Angular major).
  Check `npm install` output in the copy for peer warnings and report them.
