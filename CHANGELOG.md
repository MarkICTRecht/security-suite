# Changelog

All notable changes to Security Suite are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## v1.1.0 — 2026-06-29

First public release of **Security Suite** — a single Claude Code plugin that unifies
six upstream security projects into one coherent toolkit.

### Highlights
- **28 skills, 6 specialist subagents, 7 commands** spanning offensive security,
  defensive review, reconnaissance, and software supply-chain security.
- **Full-codebase scan framework** (`/security-scan`) that runs MEDUSA SAST +
  dependency audits + a secrets sweep + Dependabot hygiene in one pass.
- **Visual reporting** — every scan produces a standalone `report.html` dashboard
  (severity chart, metric cards, secrets table) alongside `REPORT.md` and `summary.json`.

### Included components
- 16 offensive skills + 6 subagents — from **secskills** (MIT, © Tri Luu).
- `owasp-security` — OWASP Top 10:2025 / ASVS 5.0 / LLM & Agentic AI — from
  **claude-code-owasp** (MIT).
- 7 SecLists-based skills (usernames, passwords, fuzzing, patterns, payloads,
  webshells, llm-testing) — from **awesome-skills-security** (MIT), **sanitized**.
- `recon-automation` — wraps **ReconForge** (MIT), installed at runtime.
- `sast-scanning` — wraps **MEDUSA** (AGPL-3.0), installed at runtime.
- `dependency-security` — new Dependabot supply-chain skill.
- `security-audit` — new orchestrator skill + the `security-scan.sh` engine and
  `render_report.py` HTML dashboard generator.
- Code-review commands + hooks — from **ponytail** (MIT).

### Safety
- Live, runnable malware (web-shell backdoors, `nc.exe`, reverse shells, EICAR, Flash
  exploits, archive payloads) was **removed** from the payload/webshell skills; only
  instructional content and benign wordlists remain, with pointers to upstream SecLists.
  See each skill's `NOTICE.md`.

### Licensing
- Bundled content is **MIT** (original copyright notices retained in `licenses/`).
- Wrapped tools keep their own licenses: ReconForge (MIT), **MEDUSA (AGPL-3.0)** — not
  redistributed here, installed from source at runtime. See `LICENSE` and `NOTICE.md`.

### Authorized use
For penetration testing with permission, red-team engagements under contract, defensive
review of your own code, CTFs, and security education only.
