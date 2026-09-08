#!/usr/bin/env python3
"""Render an update-and-refactor findings.json into a single self-contained HTML report.

Usage:
    python render_report.py <findings.json> -o <report.html>

The script is intentionally dependency-free (stdlib only) so it runs anywhere
Python 3 is present. All styling is inlined; the output is one portable file.
"""
import argparse
import html
import json
import sys
from pathlib import Path

SEVERITY_ORDER = {"high": 0, "medium": 1, "low": 2}
JUMP_CLASS = {"major": "jump-major", "minor": "jump-minor", "patch": "jump-patch"}
EVIDENCE_LABEL = {
    "compiler": ("verified", "ev-compiler", "Compiler-verified break"),
    "changelog": ("changelog", "ev-changelog", "From release notes (claim)"),
    "inference": ("inferred", "ev-inference", "Inferred, not verified"),
}


def esc(x):
    return html.escape(str(x if x is not None else ""))


def badge(text, cls, title=""):
    t = f' title="{esc(title)}"' if title else ""
    return f'<span class="badge {cls}"{t}>{esc(text)}</span>'


def evidence_badge(ev_type):
    label, cls, title = EVIDENCE_LABEL.get(
        ev_type, (ev_type or "?", "ev-inference", "Unspecified evidence")
    )
    return badge(label, cls, title)


def render_usage(usage):
    if not usage:
        return '<p class="muted">No usage found in code — removal candidate.</p>'
    rows = "".join(
        f"<tr><td><code>{esc(u.get('file'))}:{esc(u.get('line'))}</code></td>"
        f"<td><code>{esc(u.get('snippet'))}</code></td></tr>"
        for u in usage
    )
    return f'<table class="usage"><thead><tr><th>Location</th><th>Code</th></tr></thead><tbody>{rows}</tbody></table>'


def applies_to_project(b, build_verified):
    """Does this breaking change actually affect THIS project's code?

    The honest answer depends on how strong the evidence is:
    - An explicit boolean "applies" field always wins (the analyst's judgment,
      e.g. a non-compile break like a license requirement that still applies).
    - A compiler-verified break affects you, full stop — the build proved it.
    - On a build-verified package, an unflagged changelog claim that did NOT
      surface as a compile error is documented-but-didn't-manifest: if it broke
      your code, the trial build would have failed. So treat it as not applicable.
    - On a package with no trial build, fall back to whether the analyst tied the
      change to a real usage site.
    Behavioral/runtime changes belong in behavioral_notes, not here — this keeps
    "affects your code" meaning a genuine code break, not a documentation footnote.
    """
    v = b.get("applies")
    if isinstance(v, bool):
        return v
    if b.get("evidence_type") == "compiler":
        return True
    if build_verified:
        return False
    return bool(b.get("affected_usage"))


def render_breaking_section(items, build_verified):
    applicable = [b for b in items if applies_to_project(b, build_verified)]
    na = [b for b in items if not applies_to_project(b, build_verified)]
    n_app, n_na = len(applicable), len(na)

    if not n_app and not n_na:
        return '<h4>Breaking changes</h4><p class="ok">No breaking changes detected.</p>'
    if n_app and n_na:
        head = f'<h4>Breaking changes — {n_app} affect your code · {n_na} not applicable here</h4>'
    elif n_app:
        head = f'<h4>Breaking changes affecting your code ({n_app})</h4>'
    else:
        head = '<h4>Breaking changes — none affect your code</h4>'

    parts = [head]
    if n_app:
        parts.append(render_breaking(applicable))
    else:
        parts.append('<p class="ok">None of this release’s breaking changes touch your code.</p>')
    if n_na:
        parts.append(
            f'<details class="na"><summary>{n_na} documented breaking change(s) in this release that don’t '
            f'affect your code — click to review</summary>{render_breaking(na)}</details>'
        )
    return "".join(parts)


def render_breaking(items):
    if not items:
        return '<p class="ok">No breaking changes detected.</p>'
    items = sorted(items, key=lambda b: SEVERITY_ORDER.get(b.get("severity"), 9))
    out = []
    for b in items:
        sev = b.get("severity", "low")
        affected = b.get("affected_usage") or []
        affected_html = (
            "".join(f"<code>{esc(a)}</code> " for a in affected)
            if affected
            else '<span class="muted">no mapped usage site</span>'
        )
        out.append(
            f'''<div class="finding sev-{esc(sev)}">
  <div class="finding-head">
    {badge(sev.upper(), 'sev-badge-' + esc(sev))}
    {evidence_badge(b.get('evidence_type'))}
    <span class="finding-title">{esc(b.get('title'))}</span>
  </div>
  <div class="evidence"><strong>Evidence:</strong> <code>{esc(b.get('evidence'))}</code></div>
  <div class="affected"><strong>Affects:</strong> {affected_html}</div>
  <div class="fix"><strong>Suggested fix:</strong> {esc(b.get('fix_suggestion'))}</div>
</div>'''
        )
    return "".join(out)


def render_features(items):
    if not items:
        return '<p class="muted">No notable new features for this project.</p>'
    out = []
    for f in items:
        added = (
            badge("added in " + esc(f.get("added_in")), "ev-changelog")
            if f.get("added_in")
            else ""
        )
        example = (
            f'<div class="feature-example"><div class="ex-label">What it looks like</div>'
            f'<pre><code>{esc(f.get("example"))}</code></pre></div>'
            if f.get("example")
            else ""
        )
        benefit = (
            f'<div class="benefit"><strong>What it gives you:</strong> {esc(f.get("benefit"))}</div>'
            if f.get("benefit")
            else ""
        )
        docs = (
            f'<a class="feature-docs" href="{esc(f.get("docs_url"))}" target="_blank">Feature docs ↗</a>'
            if f.get("docs_url")
            else ""
        )
        out.append(
            f'''<div class="feature">
  <div class="feature-head"><span class="feature-title">{esc(f.get('title'))}</span> {added}</div>
  <div class="feature-desc">{esc(f.get('description'))}</div>
  {benefit}
  {example}
  <div class="relevance"><strong>Why it matters for this project:</strong> {esc(f.get('relevance'))}</div>
  <div class="suggestion"><strong>How to adopt it:</strong> {esc(f.get('suggestion'))} {docs}</div>
</div>'''
        )
    return "".join(out)


def render_behavioral(items):
    if not items:
        return ""
    rows = "".join(
        f'<li>{evidence_badge(n.get("evidence_type"))} <strong>{esc(n.get("title"))}</strong> — '
        f'{esc(n.get("impact"))} <span class="muted">({esc(n.get("evidence"))})</span></li>'
        for n in items
    )
    return f'<h4>Behavioral / default changes</h4><ul class="behavioral">{rows}</ul>'


def render_package(p):
    jump = p.get("jump", "")
    jump_badge = badge(jump.upper(), JUMP_CLASS.get(jump, "jump-patch")) if jump else ""
    bv = p.get("build_verified")
    bv_badge = (
        badge("build-verified", "ev-compiler", "A trial build was run")
        if bv
        else badge("not build-verified", "ev-inference", "No trial build — lower certainty")
    )
    breaking = p.get("breaking_changes") or []
    build_verified = bool(p.get("build_verified"))
    has_applicable = any(applies_to_project(b, build_verified) for b in breaking)
    open_attr = " open" if has_applicable else ""
    return f'''<details class="pkg"{open_attr}>
  <summary>
    <span class="pkg-name">{esc(p.get('name'))}</span>
    <span class="pkg-ver"><code>{esc(p.get('current'))}</code> → <code>{esc(p.get('latest'))}</code></span>
    {jump_badge} {bv_badge}
    <span class="pkg-verdict">{esc(p.get('verdict'))}</span>
  </summary>
  <div class="pkg-body">
    <h4>Where it's used</h4>
    {render_usage(p.get('usage'))}
    {render_breaking_section(breaking, build_verified)}
    <h4>New features</h4>
    {render_features(p.get('new_features'))}
    {render_behavioral(p.get('behavioral_notes'))}
    {f'<p class="repo"><a href="{esc(p.get("repo_url"))}" target="_blank">Source / changelog ↗</a></p>' if p.get('repo_url') else ''}
  </div>
</details>'''


def render_summary_table(packages):
    rows = []
    for p in packages:
        jump = p.get("jump", "")
        rows.append(
            f'<tr><td>{esc(p.get("name"))}</td>'
            f'<td><code>{esc(p.get("current"))}</code></td>'
            f'<td><code>{esc(p.get("latest"))}</code></td>'
            f'<td>{badge(jump.upper(), JUMP_CLASS.get(jump, "jump-patch")) if jump else ""}</td>'
            f'<td>{esc(p.get("verdict"))}</td></tr>'
        )
    return (
        '<table class="summary"><thead><tr><th>Package</th><th>Current</th>'
        '<th>Latest</th><th>Jump</th><th>Verdict</th></tr></thead><tbody>'
        + "".join(rows)
        + "</tbody></table>"
    )


STYLE = """
:root { --bg:#0f1115; --card:#1a1d24; --line:#2a2f3a; --txt:#e6e9ef; --muted:#8b93a3;
  --high:#ff5d5d; --med:#ffb020; --low:#7a8699; --ok:#39d98a; --accent:#6aa3ff; }
* { box-sizing:border-box; }
html, body { max-width:100%; overflow-x:hidden; }
body { margin:0; background:var(--bg); color:var(--txt);
  font:15px/1.55 -apple-system,Segoe UI,Roboto,sans-serif; }
.wrap { max-width:980px; margin:0 auto; padding:32px 24px 80px; }
h1 { font-size:24px; margin:0 0 4px; }
h4 { margin:18px 0 8px; color:var(--accent); font-size:13px; text-transform:uppercase; letter-spacing:.04em; }
.sub { color:var(--muted); margin:0 0 24px; }
code { background:#0b0d11; padding:1px 5px; border-radius:4px; font-size:.9em;
  overflow-wrap:anywhere; word-break:break-word; }
a { color:var(--accent); }
.muted { color:var(--muted); } .ok { color:var(--ok); }
.badge { display:inline-block; padding:1px 8px; border-radius:10px; font-size:11px;
  font-weight:600; vertical-align:middle; margin-right:4px; }
.jump-major { background:#3a1414; color:var(--high); }
.jump-minor { background:#3a2e10; color:var(--med); }
.jump-patch { background:#15242f; color:var(--accent); }
.sev-badge-high { background:#3a1414; color:var(--high); }
.sev-badge-medium { background:#3a2e10; color:var(--med); }
.sev-badge-low { background:#1f2530; color:var(--low); }
.ev-compiler { background:#10301f; color:var(--ok); }
.ev-changelog { background:#1f2530; color:var(--accent); }
.ev-inference { background:#2b1f10; color:var(--med); }
table { border-collapse:collapse; width:100%; margin:6px 0; }
th,td { text-align:left; padding:7px 10px; border-bottom:1px solid var(--line);
  vertical-align:top; overflow-wrap:anywhere; word-break:break-word; }
.usage { table-layout:fixed; }
.usage th:first-child, .usage td:first-child { width:46%; }
th { color:var(--muted); font-weight:600; font-size:12px; text-transform:uppercase; }
.summary { background:var(--card); border-radius:10px; overflow:hidden; margin-bottom:28px; }
.pkg { background:var(--card); border:1px solid var(--line); border-radius:12px;
  margin:12px 0; padding:0 18px; }
.pkg summary { cursor:pointer; padding:16px 0; list-style:none; display:flex;
  flex-wrap:wrap; align-items:center; gap:10px; }
.pkg summary::-webkit-details-marker { display:none; }
.pkg-name { font-weight:700; font-size:16px; }
.pkg-verdict { color:var(--muted); margin-left:auto; font-size:13px; }
.pkg-body { padding:0 0 18px; border-top:1px solid var(--line); }
.finding { border-left:3px solid var(--low); background:#0d1016; border-radius:6px;
  padding:10px 14px; margin:8px 0; }
.finding.sev-high { border-left-color:var(--high); }
.finding.sev-medium { border-left-color:var(--med); }
.finding-head { display:flex; align-items:center; gap:6px; margin-bottom:6px; }
.finding-title { font-weight:600; }
.finding .evidence, .finding .affected, .finding .fix { font-size:13px; margin:3px 0; color:#c8cedb; }
.na { margin:6px 0 2px; opacity:.62; }
.na > summary { cursor:pointer; color:var(--muted); font-size:13px; padding:4px 0; list-style:none; }
.na > summary::-webkit-details-marker { display:none; }
.na > summary::before { content:"▸ "; }
.na[open] > summary::before { content:"▾ "; }
.feature { background:#0d1016; border-radius:6px; padding:12px 14px; margin:10px 0;
  border-left:3px solid var(--ok); }
.feature-head { display:flex; align-items:center; gap:8px; margin-bottom:4px; }
.feature-title { font-weight:700; color:var(--ok); font-size:15px; }
.feature-desc { font-size:14px; color:#dde2ea; margin:2px 0 6px; }
.feature .benefit, .feature .relevance, .feature .suggestion { font-size:13px; margin-top:5px; color:#c8cedb; }
.feature-example { margin:8px 0; }
.feature-example .ex-label { font-size:11px; text-transform:uppercase; letter-spacing:.04em;
  color:var(--muted); margin-bottom:3px; }
.feature-example pre { background:#06080c; border:1px solid var(--line); border-radius:6px;
  padding:10px 12px; overflow-x:auto; margin:0; }
.feature-example pre code { background:none; padding:0; font-size:12.5px; line-height:1.5; }
.feature-docs { margin-left:6px; white-space:nowrap; }
.behavioral li { margin:6px 0; }
.usage code { font-size:.85em; }
.repo { margin-top:14px; }
"""


def build_html(data):
    packages = data.get("packages", [])
    cards = "".join(render_package(p) for p in packages)
    summary_table = render_summary_table(packages) if packages else "<p>No packages analyzed.</p>"
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Update &amp; Refactor — {esc(data.get('project'))}</title>
<style>{STYLE}</style></head><body><div class="wrap">
<h1>Update &amp; Refactor — {esc(data.get('project'))}</h1>
<p class="sub">Generated {esc(data.get('generated'))} · {esc(data.get('summary'))}</p>
<h4>At a glance</h4>
{summary_table}
{cards}
<p class="sub" style="margin-top:32px">Evidence badges:
{badge('verified','ev-compiler')} a build produced it ·
{badge('changelog','ev-changelog')} from release notes ·
{badge('inferred','ev-inference')} not verified — confirm before relying on it.</p>
</div></body></html>"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("findings", help="path to findings.json")
    ap.add_argument("-o", "--out", default="report.html", help="output HTML path")
    args = ap.parse_args()

    try:
        data = json.loads(Path(args.findings).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"error reading {args.findings}: {e}", file=sys.stderr)
        return 1

    Path(args.out).write_text(build_html(data), encoding="utf-8")
    print(f"wrote {args.out} ({len(data.get('packages', []))} packages)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
