---
name: recon-automation
description: Automate authorized external reconnaissance with ReconForge — subdomain discovery (crt.sh), concurrent port scanning, technology fingerprinting, scope validation, and Markdown reporting with AI triage prompts. Use when mapping the attack surface of an in-scope target, running bug-bounty recon, or turning raw recon output into prioritized findings.
allowed-tools: Bash Read Write Grep Glob WebFetch
---

# Recon Automation (ReconForge)

A thin wrapper around **ReconForge** — an AI-assisted recon toolkit for authorized
bug-bounty and security research. This skill installs the tool on demand and drives
it through a repeatable recon workflow. ReconForge upstream:
https://github.com/ferasbusiness666/ReconForge (MIT).

> **Authorization first.** Only run reconnaissance against assets you own or are
> explicitly authorized to test (signed engagement, bug-bounty scope, written
> permission). Use the built-in scope check to enforce this on every run.

## Install (run once)

```bash
# Preferred: isolated install from source
git clone https://github.com/ferasbusiness666/ReconForge.git
cd ReconForge && pip install . --break-system-packages
reconforge --version
```

If `reconforge` is already on PATH, skip installation.

## Core workflow

1. **Define and validate scope.** Never scan anything that fails the scope check.

   ```bash
   reconforge scopecheck -t target.example.com --scope scope.txt
   ```

   `scope.txt` supports exact hosts, wildcards (`*.example.com`), IP ranges, and CIDR.

2. **Subdomain discovery** (passive, certificate-transparency via crt.sh):

   ```bash
   reconforge subdomains -d example.com            # cached 24h by default
   reconforge subdomains -d example.com --no-cache # force fresh
   ```

3. **Port scanning** (concurrent, in-scope hosts only):

   ```bash
   reconforge portscan -t api.example.com
   reconforge portscan -t api.example.com -p 1-1024   # custom range
   ```

4. **Technology detection** (headers, cookies, body signals):

   ```bash
   reconforge techdetect -u https://api.example.com
   ```

5. **Generate a report** and triage:

   ```bash
   reconforge report -o recon-report.md
   ```

## AI triage

After collection, read the generated report and the raw findings, then prioritize.
For each interesting host/service produce a one-line hypothesis ranked by likely
impact: `<host:port/tech> — <suspected issue> — <next check>`. Pull the highest-value
candidates first (auth flows, exposed admin panels, API surfaces, stale tech with
known CVEs). Cross-reference with the `performing-reconnaissance`,
`enumerating-network-services`, and `dependency-security` skills for deeper follow-up.

## Notes

- Help is available per subcommand: `reconforge <command> --help`.
- Results cache under the tool's cache dir; use `--no-cache` to bypass.
- Keep all output inside the engagement folder; never exfiltrate target data.
