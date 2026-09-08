# Generic ecosystem fallback

Use this for any dependency manifest without a dedicated reference file. The
shape of the work is identical to the others — only the commands change. Figure
out the four primitives below for the ecosystem in front of you, then proceed
through the standard pipeline.

If a quick check of the tool's docs (Context7, official docs, `--help`) gives
you the commands, use them. State in the report that this ecosystem used the
generic path, so the user knows it had less specialized handling than NuGet/
npm/PyPI.

## The four primitives to find

1. **List declared (direct) dependencies + installed versions.**
   - Go: `go.mod` + `go list -m all`
   - Rust: `Cargo.toml` + `cargo tree --depth 1`
   - Java/Maven: `pom.xml` + `mvn dependency:list`
   - Gradle: `build.gradle` + `gradle dependencies`
   - PHP: `composer.json` + `composer show --direct`
   - Ruby: `Gemfile` + `bundle list`

2. **Find the latest stable version of a package.**
   - Go: `go list -m -versions <module>`
   - Rust: `cargo search <crate>` or the crates.io API
   - Maven: search Maven Central
   - Gradle: depends on repo; query the artifact repository
   - composer: `composer outdated --direct`
   - bundler: `bundle outdated`
   Exclude prereleases unless the project already uses one.

3. **Map a package to its usage in code.** Determine how this ecosystem's import
   mechanism names packages, then grep:
   - Go: import path (often the module path or a subpackage of it)
   - Rust: crate name → `use <crate>::...` (note `-`/`_` normalization)
   - Java: package/group → `import com.example...`
   - PHP: namespace via PSR-4 autoload map in composer.json
   Capture file + line + snippet, and the call sites, not just imports.

4. **Build-verify if the ecosystem compiles.**
   - Go: `go build ./...` / `go vet ./...`
   - Rust: `cargo build`
   - Maven: `mvn -q compile`
   - Gradle: `gradle compileJava`
   Do it in a scratchpad copy with the version bumped. Compiler errors are
   ground-truth breaks. For interpreted ecosystems (Ruby, PHP) with no compile
   step, lean on the changelog and the project's test suite, and say the breaks
   are detected with lower certainty.

## Then

Continue exactly as the dedicated references do: changelog pass
(`references/changelog-sources.md`), classify breaking changes / new features /
behavioral notes, write `findings.json`, render the report. Nothing about the
report, plan, or apply phases changes by ecosystem.
