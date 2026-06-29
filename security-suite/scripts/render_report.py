#!/usr/bin/env python3
"""Render a Security Suite scan into a styled, standalone HTML dashboard.

Usage:  render_report.py <output-dir>
Reads:  <output-dir>/summary.json  (+ optional detail files secrets.txt, medusa.txt, …)
Writes: <output-dir>/report.html   (self-contained; Chart.js from CDN, graceful offline)
"""
import json, sys, html, datetime, pathlib

def main():
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    s = json.loads((out / "summary.json").read_text(encoding="utf-8"))

    sev = s.get("sast", {})
    crit, high, med, low = (int(sev.get(k, 0) or 0) for k in ("critical", "high", "medium", "low"))
    secrets = int(s.get("secrets", {}).get("count", 0) or 0)
    secret_sample = s.get("secrets", {}).get("sample", [])
    deps = s.get("dependencies", [])
    dependabot = bool(s.get("dependabot", False))
    sast_ran = s.get("sast", {}).get("ran", False)

    # overall posture
    issues = crit + high
    if not sast_ran and secrets == 0:
        verdict, vcolor = "Incomplete", "#64748b"
    elif crit > 0 or secrets > 0:
        verdict, vcolor = "Action required", "#dc2626"
    elif high > 0:
        verdict, vcolor = "Needs attention", "#d97706"
    else:
        verdict, vcolor = "Looking clean", "#16a34a"

    def esc(x): return html.escape(str(x))
    dep_rows = "".join(f"<li>{esc(d)}</li>" for d in deps) or "<li>No dependency manifests detected.</li>"
    secret_rows = "".join(f"<tr><td>{esc(l)}</td></tr>" for l in secret_sample[:25])
    if not secret_rows:
        secret_rows = "<tr><td class='ok'>✓ No high-signal secret patterns matched.</td></tr>"

    cards = [
        ("Critical", crit, "#dc2626"),
        ("High", high, "#ea580c"),
        ("Medium", med, "#d97706"),
        ("Low", low, "#0891b2"),
        ("Secret matches", secrets, "#7c3aed"),
        ("Dependabot", "Yes" if dependabot else "No", "#16a34a" if dependabot else "#dc2626"),
    ]
    card_html = "".join(
        f'<div class="card"><div class="card-v" style="color:{c}">{esc(v)}</div>'
        f'<div class="card-l">{esc(l)}</div></div>' for l, v, c in cards
    )

    tmpl = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Security scan — {esc(s.get('project',''))}</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
:root{{--bg:#0b1020;--panel:#141b2e;--panel2:#1b2440;--ink:#e7ecf5;--mut:#94a3b8;--line:#27314f}}
*{{box-sizing:border-box}}
body{{margin:0;font:15px/1.5 -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:var(--bg);color:var(--ink)}}
.wrap{{max-width:1040px;margin:0 auto;padding:32px 20px 64px}}
header{{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;flex-wrap:wrap;border-bottom:1px solid var(--line);padding-bottom:20px}}
h1{{font-size:22px;margin:0 0 4px}}
.sub{{color:var(--mut);font-size:13px}}
.verdict{{padding:8px 16px;border-radius:999px;font-weight:700;color:#fff;white-space:nowrap}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin:24px 0}}
.card{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:18px}}
.card-v{{font-size:30px;font-weight:800;line-height:1}}
.card-l{{color:var(--mut);font-size:13px;margin-top:6px}}
.row{{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-top:6px}}
@media(max-width:760px){{.row{{grid-template-columns:1fr}}}}
.panel{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}}
.panel h2{{font-size:15px;margin:0 0 14px;letter-spacing:.04em;text-transform:uppercase;color:var(--mut)}}
table{{width:100%;border-collapse:collapse;font-size:13px}}
td{{padding:8px 10px;border-bottom:1px solid var(--line);font-family:ui-monospace,Menlo,Consolas,monospace;word-break:break-all}}
.ok{{color:#4ade80;font-family:inherit}}
ul{{margin:0;padding-left:18px}} li{{margin:4px 0}}
.foot{{color:var(--mut);font-size:12px;margin-top:28px;border-top:1px solid var(--line);padding-top:16px}}
canvas{{max-height:220px}}
</style></head><body><div class="wrap">
<header>
  <div>
    <h1>🛡️ Security scan — {esc(s.get('project',''))}</h1>
    <div class="sub">{esc(s.get('target',''))} · {esc(s.get('date',''))} · mode: {esc(s.get('mode','full'))} · Security Suite</div>
  </div>
  <div class="verdict" style="background:{vcolor}">{esc(verdict)}</div>
</header>

<div class="grid">{card_html}</div>

<div class="row">
  <div class="panel"><h2>Severity breakdown (SAST)</h2><canvas id="sev"></canvas>
    {"" if sast_ran else "<p class='sub'>MEDUSA was not run — install it for code-level findings.</p>"}</div>
  <div class="panel"><h2>Dependencies / supply chain</h2><ul>{dep_rows}</ul>
    <p class="sub" style="margin-top:14px">Dependabot config: <b style="color:{'#4ade80' if dependabot else '#f87171'}">{'present' if dependabot else 'missing'}</b></p></div>
</div>

<div class="panel" style="margin-top:18px"><h2>Secrets / sensitive data ({secrets})</h2>
  <table><tbody>{secret_rows}</tbody></table></div>

<div class="foot">Generated by the Security Suite scan framework. Detailed outputs: REPORT.md,
medusa.txt, secrets.txt, *-audit.*. Triage with the <b>owasp-security</b> skill. Defensive / authorized use only.</div>
</div>
<script>
const ctx=document.getElementById('sev');
if(ctx&&window.Chart){{new Chart(ctx,{{type:'doughnut',
 data:{{labels:['Critical','High','Medium','Low'],
  datasets:[{{data:[{crit},{high},{med},{low}],
   backgroundColor:['#dc2626','#ea580c','#d97706','#0891b2'],borderColor:'#141b2e',borderWidth:3}}]}},
 options:{{plugins:{{legend:{{position:'bottom',labels:{{color:'#94a3b8',padding:14}}}}}},cutout:'62%'}}}});}}
</script></body></html>"""
    (out / "report.html").write_text(tmpl, encoding="utf-8")
    print(f"HTML report: {out/'report.html'}")

if __name__ == "__main__":
    main()
