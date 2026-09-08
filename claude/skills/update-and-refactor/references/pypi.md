# PyPI (Python)

## Manifests

- `requirements*.txt` — `pkg==1.2.3`, `pkg>=1.2`, etc.
- `pyproject.toml` — `[project].dependencies` or tool-specific
  (`[tool.poetry.dependencies]`).
- `Pipfile`, `setup.py`/`setup.cfg` — older or alternate.

Direct deps are what's declared here. Pinned (`==`) vs ranged (`>=`, `~=`)
matters: a ranged spec may already permit the update.

## Inventory outdated

In the project's environment (activate the venv if there is one):

```bash
pip list --outdated
```

Columns: `Version` (installed), `Latest`, `Type`. For a clean read tied to the
declared deps rather than the whole environment, cross-reference against the
manifest — `pip list --outdated` reports everything installed, including
transitive packages. Keep the inventory to direct deps unless asked.
`pip list --outdated --format=json` for scripting. Exclude prereleases unless the
project already uses one.

## Map package → usage in code

Python's trap: the **distribution name** (what you `pip install`) is often not
the **import name** (what you `import`). Examples:

- `beautifulsoup4` → `import bs4`
- `PyYAML` → `import yaml`
- `Pillow` → `import PIL`
- `scikit-learn` → `import sklearn`
- `azure-ai-ml` → `from azure.ai.ml import ...`

Resolve the import name before grepping. Reliable methods:
- `pip show -f <dist>` lists installed files; the top-level package dir is the
  import name.
- Check the package's `top_level.txt` in its `.dist-info`, or its docs.

Then grep for `import <name>`, `from <name> import`, `from <name>.sub import`.
Capture the actual attribute/function calls too — that's the break surface.
Zero usage on an outdated dep → removal candidate; report it.

## Build-verify (limited — Python is interpreted)

Python has no compile step that catches API breaks ahead of runtime, so there's
no `tsc`/`dotnet build` equivalent for ground truth. Get the strongest signal
available, in this order:

1. **Trial install + import-and-test in a copy.** Create a throwaway venv in the
   scratchpad, install the bumped version, and run the project's test suite if it
   has one (`pytest`). Test failures and `ImportError`/`AttributeError`/
   `TypeError` at collection time are your closest thing to verified breaks.
2. **Static type check** if the project uses type hints and the package ships
   stubs: `mypy` or `pyright` against the call sites can surface signature breaks
   without running code. Worth doing when available; many packages lack stubs.
3. **Changelog is primary here.** Because runtime is the only full truth and you
   can't exercise every path, the changelog/migration-guide pass carries more
   weight for Python than for compiled ecosystems. Be explicit in the report that
   Python breaks are detected with lower certainty and recommend the user run
   their own tests after applying.

Map signals:
- `ImportError` / `ModuleNotFoundError` — module moved or removed
- `AttributeError` on a known symbol — renamed/removed member
- `TypeError` on a call — signature changed
- `DeprecationWarning` (run with `-W error::DeprecationWarning` to surface) —
  deprecation, report as behavioral

## Notes

- Distinguish runtime deps from dev/test deps (often in a separate
  `requirements-dev.txt` or an optional group) — blast radius differs.
- A bumped package may raise the minimum Python version; check its metadata and
  flag if it exceeds the project's target.
