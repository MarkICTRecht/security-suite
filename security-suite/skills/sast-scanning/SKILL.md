---
name: sast-scanning
description: Run multi-language static application security testing with MEDUSA — a unified scanner that orchestrates 70+ language linters/SAST tools (bandit, eslint, semgrep, gosec, hadolint, trivy, secrets/MCP/AI-config scanners) and triages false positives. Use when scanning a codebase for vulnerabilities, secrets, insecure config, or before a release/security gate.
allowed-tools: Bash Read Write Grep Glob
---

# SAST Scanning (MEDUSA)

Wrapper around **MEDUSA** — a universal security scanner that runs and normalizes the
output of many specialized linters/SAST tools across languages, plus its own scanners
for secrets, environment files, Markdown, MCP servers, AI chat histories, and
agent-planning artifacts. Upstream: https://github.com/Pantheon-Security/medusa.

Use this for **defensive** review of code you own or are authorized to assess. Pair it
with the `owasp-security` skill (standards/remediation) and `dependency-security`
(supply chain).

## Install (run once)

```bash
pip install medusa-security --break-system-packages
medusa --version
# or from source:
# git clone https://github.com/Pantheon-Security/medusa.git && cd medusa && pip install -e . --break-system-packages
```

## Workflow

1. **Initialize** in the project root — detects languages, available scanners, and
   wires IDE integration:

   ```bash
   cd /path/to/project
   medusa init
   ```

   Creates `.medusa.yml` and (for Claude Code) `.claude/commands/medusa-scan.md`.

2. **Install missing linters** the project needs:

   ```bash
   medusa install --all
   ```

   Tools span ecosystems (pip: bandit/semgrep; npm: eslint/stylelint; apt:
   shellcheck/hadolint; gem: rubocop; etc.). Install only what the codebase uses.

3. **Scan:**

   ```bash
   medusa scan .            # full scan
   medusa scan . --quick    # fast pass, good for pre-commit / CI gate
   medusa scan . -w 6       # set worker count
   ```

   Reports are written to `.medusa/reports/` (JSON). Summary prints CRITICAL/HIGH/
   MEDIUM/LOW counts.

4. **Review results:**

   ```bash
   cat .medusa/reports/parallel_scan_temp.json
   ```

## Triage guidance

Read the JSON report and group findings by severity, then by file. For each HIGH/
CRITICAL: confirm it's reachable (not dead code/test fixture), map it to the relevant
OWASP category via the `owasp-security` skill, and propose the minimal fix. Document
genuine false positives in `.medusa.yml` with a reason so they stay suppressed.

## Release gate pattern

For a hard pre-release check, fail the build on new HIGH/CRITICAL findings:

```bash
medusa scan . --quick   # run in CI; compare against the previous baseline report
```

## Notes

- If installed linters appear "missing" in a sandbox, ensure their bin dirs
  (`~/.local/bin`, `~/.npm-global/bin`) are on PATH before scanning.
- `medusa` ships extra scanners for AI/agent supply chain (MCP servers, prompt/agent
  planning files) — useful when reviewing AI-integrated codebases.
