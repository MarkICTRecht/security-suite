---
description: Run a full defensive security scan on a codebase (SAST + deps + secrets + supply chain) and triage the findings
argument-hint: "[path or git-url] [--quick]"
allowed-tools: Bash Read Grep Glob
---

Run a complete security scan of the target using the Security Suite scan engine, then
triage the results.

Target: `{{args}}` (defaults to the current directory if empty).

Steps:

1. Run the scan engine:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/security-scan.sh" {{args}}
   ```

   The script auto-installs MEDUSA / pip-audit if missing, clones the repo when given a
   git URL, and writes to `./security-reports/<timestamp>/`: a visual `report.html`
   dashboard, a `REPORT.md`, `summary.json`, and raw tool outputs.

2. Read the generated `REPORT.md` (and `medusa.txt`, `secrets.txt`, `*-audit.*` detail
   files). Tell the user the `report.html` dashboard is available to open/share.

3. Triage using the **`owasp-security`** skill: for each HIGH/CRITICAL finding, confirm
   it is reachable (not a test fixture or dead code), map it to its OWASP 2025 category,
   and propose the minimal fix. Verify every secret match — flag true positives for
   rotation. If `.github/dependabot.yml` is missing, offer to create one via the
   **`dependency-security`** skill.

4. Summarize: a prioritized, deduplicated action list ordered by severity, with the
   concrete remediation for each item.

Keep the summary tight — the full detail already lives in the report files.
