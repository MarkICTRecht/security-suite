# Security Suite — unified Claude Code security plugin

A single Claude Code plugin that combines **six upstream security projects** into one
coherent toolkit: **28 skills**, **6 specialist subagents**, and **7 commands**,
spanning offensive security, defensive review, reconnaissance automation, software
supply-chain security, and a reusable **full-codebase scan framework**.

> ⚠️ **Authorized use only.** The offensive skills, wordlists, and recon tooling in this
> suite are for penetration testing, red-team engagements, security research, and CTFs
> **on systems you own or are explicitly authorized to test**. Misuse may be illegal.
> See `NOTICE.md` for licensing/attribution and what was sanitized for safe distribution.

## What's inside

| Source project | Contribution |
|---|---|
| [secskills](https://github.com/trilwu/secskills) | 16 offensive-security skills + 6 specialist subagents |
| [claude-code-owasp](https://github.com/agamm/claude-code-owasp) | `owasp-security` defensive standards skill (OWASP Top 10:2025, ASVS 5.0, LLM/Agentic AI) |
| [awesome-skills-security](https://github.com/Eyadkelleh/awesome-skills-security) | 7 SecLists-based skills (wordlists, payloads, patterns, webshells, LLM testing) — sanitized |
| [ReconForge](https://github.com/ferasbusiness666/ReconForge) | wrapped as the `recon-automation` skill |
| [medusa](https://github.com/Pantheon-Security/medusa) | wrapped as the `sast-scanning` skill (70+ linters) |
| [Dependabot](https://github.com/dependabot) | new `dependency-security` skill (supply-chain) |
| [ponytail](https://github.com/DietrichGebert/ponytail) | code-review commands + hooks (secure, minimal code) |

## Install

**From a folder / zip** (unzip `security-suite.zip` first):

```bash
/plugin marketplace add /path/to/security-suite
/plugin install security-suite@security-suite-marketplace
```

**From GitHub** (best for teams — supports updates):

```bash
/plugin marketplace add <owner>/security-suite
/plugin install security-suite@security-suite-marketplace
/plugin marketplace update security-suite-marketplace   # later, to pull updates
```

The plugin auto-discovers everything under `security-suite/skills`, `…/agents`,
`…/commands`, runs `…/scripts/`, and wires `…/hooks/claude-codex-hooks.json`.

The two wrapped tools (ReconForge, MEDUSA) are **not bundled** — their skills install
them on first use via `pip`/`git`, so nothing extra is needed up front.

## Repository layout

```
security-suite/                      ← marketplace repo (share this)
├─ .claude-plugin/marketplace.json   ← marketplace entry
├─ README.md  ·  LICENSE  ·  NOTICE.md
├─ licenses/                         ← full upstream license texts
└─ security-suite/                   ← the plugin itself
   ├─ .claude-plugin/plugin.json
   ├─ skills/      (28 skills)
   ├─ agents/      (6 subagents)
   ├─ commands/    (7 commands incl. /security-scan)
   ├─ scripts/     (security-scan.sh — the scan engine)
   └─ hooks/       (ponytail hooks)
```

## 🔍 Full-codebase scan framework

A reusable engine to scan any project (local path or git URL) on **all defensive
points at once** — SAST, vulnerable dependencies, hardcoded secrets, and supply-chain
hygiene — producing a single consolidated report.

```bash
# inside Claude Code (the command auto-installs tools and triages the results):
/security-scan .                                  # current project
/security-scan ~/projects/myapp --quick
/security-scan https://github.com/me/myrepo.git   # clone & scan

# or run the engine directly:
bash security-suite/scripts/security-scan.sh <path|git-url> [--quick] [--no-install]
```

It runs four stages — **MEDUSA** SAST → **dependency audits** (npm/pip/go/bundler) →
**secrets sweep** → **Dependabot** hygiene — and writes three things to
`security-reports/<timestamp>/`:

- **`report.html`** — a styled, standalone dashboard (severity doughnut chart, metric
  cards, secrets table, supply-chain status) you can open in any browser or share.
- **`REPORT.md`** — the same findings in Markdown for the terminal / pull requests.
- **`summary.json`** + raw tool outputs (`medusa.txt`, `secrets.txt`, `*-audit.*`).

The `security-audit` skill / `/security-scan` command then triage findings against
OWASP 2025 with concrete fixes. Tools that aren't installed are skipped gracefully, so
a first run works even on a bare machine. Extend it by adding stages to the single
readable script.

## Skill index by category

### 🔴 Offensive — recon & initial access
- `initial-access-recon` — OSINT, subdomain enum, port scanning, attack-surface mapping
- `recon-automation` — drives **ReconForge** (crt.sh subdomains, port scan, tech detect, scope check, reports)
- `network-service-enumeration` — SMB/FTP/SSH/RDP/HTTP/DBs/LDAP/NFS/DNS/SNMP
- `phishing-social-engineering` — phishing, credential harvesting, pretexting

### 🔴 Offensive — exploitation
- `web-app-security` — SQLi, XSS, command injection, JWT, SSRF, file upload, XXE
- `api-security-testing` — REST/GraphQL auth bypass, IDOR, mass assignment, rate limits
- `active-directory-attacks` — Kerberoasting, ASREPRoast, DCSync, PtH/PtT, BloodHound
- `wireless-attacks` — WPA/WPA2 cracking, WPS, Evil Twin, deauth
- `mobile-pentesting` — Android/iOS, APK analysis, SSL pinning & root/jailbreak bypass
- `web3-blockchain` — smart-contract audit: reentrancy, overflow, access control, DeFi
- `container-security` — Docker escape, Kubernetes cluster exploitation

### 🔴 Offensive — post-exploitation
- `linux-privilege-escalation` — SUID/SGID, capabilities, sudo, cron, kernel
- `windows-privilege-escalation` — service misconfig, DLL hijack, tokens, UAC bypass
- `password-attacks` — hashcat/john, spraying, brute force, pass-the-hash
- `persistence-techniques` — registry, scheduled tasks, services, cron, backdoors
- `file-transfer-techniques` — HTTP/SMB/FTP/netcat/base64, living-off-the-land
- `cloud-security` — AWS/Azure/GCP misconfig, IAM, metadata, serverless privesc

### 🟢 Defensive — review, standards, supply chain
- `security-audit` — **full-codebase scan framework**: orchestrates SAST + deps + secrets + supply chain into one report, then triages against OWASP
- `owasp-security` — OWASP Top 10:2025, ASVS 5.0, LLM Top 10, Agentic AI; per-language quirks
- `sast-scanning` — drives **MEDUSA** multi-language SAST (bandit, eslint, semgrep, gosec, trivy, secrets/MCP/AI scanners)
- `dependency-security` — **Dependabot** config, alert triage, secure auto-merge, CVE remediation

### 🧰 Wordlists, payloads & detection (SecLists-based)
- `security-usernames` — username/default-credential lists for authorized enumeration
- `security-passwords` — common/leaked/worst password lists (curated <10MB)
- `security-fuzzing` — SQLi/command-injection/special-char fuzzing payloads
- `security-patterns` — sensitive-data regexes (API keys, cards, SSNs, emails, IPs)
- `security-payloads` — filename/null-byte injection test payloads *(binaries removed — see its `NOTICE.md`)*
- `security-webshells` — web-shell detection signatures *(live shells removed — see its `NOTICE.md`)*
- `llm-testing` — LLM safety/robustness test prompts (bias, leakage, alignment, adversarial)

## Specialist subagents
`pentester` · `cloud-pentester` · `mobile-pentester` · `recon-specialist` ·
`red-team-operator` · `web3-auditor` — each launches with a focused security toolset and
is invoked proactively when the conversation matches its domain.

## Code-review commands (ponytail)
`/ponytail` (lite/full/ultra) · `/ponytail-review` · `/ponytail-audit` ·
`/ponytail-debt` · `/ponytail-gain` · `/ponytail-help` — enforce minimal, secure,
no-over-engineering code while keeping every safety guard (validation, error handling,
security measures are never simplified away). A natural companion to secure code review.

## Typical workflows

- **Authorized pentest:** `recon-specialist`/`recon-automation` → `network-service-enumeration`
  → `web-app-security`/`api-security-testing` → privilege-escalation skills →
  `red-team-operator` for persistence & exfil simulation.
- **Secure SDLC / defensive:** `sast-scanning` (code) + `dependency-security` (deps) +
  `owasp-security` (standards) + `/ponytail-review` on the diff before merge.

## Licensing

This is an aggregate work; parts carry different licenses. Full texts are in
[`licenses/`](licenses/); the model is set out in [`LICENSE`](LICENSE).

- **Original content** (scan framework, the `security-audit` / `sast-scanning` /
  `recon-automation` / `dependency-security` skills, manifests, docs) — **MIT**,
  © 2026 ICTRecht / Mark Zijlstra.
- **Bundled upstream** (secskills, claude-code-owasp, awesome-skills-security, ponytail,
  and the SecLists-derived wordlists) — all **MIT**, original copyright notices retained.
- **Wrapped, not bundled:** ReconForge (**MIT**) and **MEDUSA (AGPL-3.0)** are installed
  from their own sources at runtime. No MEDUSA source ships here, so its AGPL copyleft
  does not attach to this package — but when you install MEDUSA you receive it under
  AGPL-3.0 and must comply with that license in your own use.

See [`NOTICE.md`](NOTICE.md) for the per-component attribution table and the
sanitization policy applied to the SecLists payload/webshell skills.

## Responsible use

For authorized penetration testing, red-team engagements under contract, defensive
review of your own code, CTFs, and security education only. You are responsible for
having explicit authorization for any target you test. Live malware samples have been
removed from the payload/webshell skills (see their `NOTICE.md`).
