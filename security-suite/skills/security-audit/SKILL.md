---
name: security-audit
description: Orchestrate a full defensive security audit of a codebase by combining MEDUSA SAST, dependency/supply-chain audits, a secrets sweep, and Dependabot hygiene into one consolidated report, then triaging findings against OWASP 2025. Use when the user wants to "scan a project/codebase/repo for security issues", run a full security review, or audit code they built before shipping.
allowed-tools: Bash Read Write Grep Glob WebFetch
---

# Security Audit (full-codebase scan framework)

This is the **orchestrator** that ties the suite's defensive skills into one repeatable
workflow you can run on any project (local path or git URL). It produces a single
Markdown report and a prioritized remediation list.

## When to use

The user wants a whole project scanned "on all points" — code vulnerabilities, secrets,
vulnerable dependencies, and supply-chain hygiene — rather than one isolated check.

## How to run

Use the bundled engine (auto-installs tools, clones git URLs, writes a timestamped
report under `./security-reports/` — including a visual `report.html` dashboard, a
`REPORT.md`, and `summary.json`):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/security-scan.sh" <path|git-url> [--quick] [--no-install]
```

Or invoke the slash command `/security-scan <path|git-url>`.

The engine runs four stages:

| Stage | Tool / skill | Covers |
|---|---|---|
| 1. SAST | **MEDUSA** (`sast-scanning`) | code vulns, insecure config, secrets, 70+ language linters |
| 2. Dependencies | npm audit / pip-audit / govulncheck / bundler-audit (`dependency-security`) | known CVEs in dependencies |
| 3. Secrets sweep | high-signal regexes (`security-patterns`) | hardcoded keys, tokens, private keys, passwords |
| 4. Dependabot hygiene | `.github/dependabot.yml` check (`dependency-security`) | automated patching configured? |

## Then triage (this is the important part)

Reading the report is step one; the value is in triage. After the scan:

1. **Severity + reachability** — for each HIGH/CRITICAL, confirm the vulnerable code is
   actually reachable (not a test fixture, example, or dead path). Drop confirmed false
   positives with a one-line reason.
2. **Map to OWASP** — use the `owasp-security` skill to classify each finding (A01–A10:2025,
   plus LLM/Agentic AI categories where relevant) and pull the standard remediation.
3. **Secrets** — verify every match in `secrets.txt`. Any real credential must be rotated
   and moved to a secret manager / environment variable, not just deleted from HEAD.
4. **Dependencies** — for each vulnerable package, bump to the patched version (or
   replace it); note transitive deps that also need pinning.
5. **Supply chain** — if no `dependabot.yml`, generate one via `dependency-security`.

## Output

Deliver a deduplicated, severity-ordered action list: `[SEV] <finding> → <fix>` with the
report path. Keep it concise — detail lives in the report files
(`REPORT.md`, `medusa.txt`, `secrets.txt`, `*-audit.*`).

## Customizing the framework

The engine is a single readable script at `scripts/security-scan.sh`. Add stages (e.g.
`semgrep --config auto`, container/IaC scans, license checks) by following the existing
stage pattern, or gate stages behind flags. Keep additions minimal and degrade
gracefully when a tool is absent.

## Scope

Defensive use on code you own or maintain. For external/authorized offensive testing,
use the recon and exploitation skills instead.
