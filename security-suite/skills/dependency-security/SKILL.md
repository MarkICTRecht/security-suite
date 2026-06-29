---
name: dependency-security
description: Secure the software supply chain with Dependabot — configure dependabot.yml for version and security updates, enable/triage Dependabot alerts, group and auto-merge low-risk PRs, and remediate vulnerable dependencies. Use when setting up dependency scanning, responding to a CVE in a dependency, hardening a repo's supply chain, or reviewing a Dependabot pull request.
allowed-tools: Read Write Grep Glob Bash WebFetch
---

# Dependency Security (Dependabot)

GitHub **Dependabot** keeps a repository's dependencies up to date and surfaces known
vulnerabilities. This skill covers the three pillars — **alerts**, **security
updates**, and **version updates** — and how to configure, triage, and remediate.
Reference: https://github.com/dependabot · https://docs.github.com/code-security/dependabot

Use this for **defensive** supply-chain hardening of repos you own or maintain. Pair
with `sast-scanning` (code) and `owasp-security` (A06: Vulnerable & Outdated
Components).

## 1. Enable Dependabot (repo settings)

In a GitHub repo: **Settings → Code security**, enable:
- **Dependency graph** (prerequisite for everything else)
- **Dependabot alerts** — notifies on known CVEs in your dependencies
- **Dependabot security updates** — auto-opens PRs to patch vulnerable versions

These can also be enabled org-wide via security configurations.

## 2. Configure version updates — `.github/dependabot.yml`

Create `.github/dependabot.yml` to schedule routine dependency bumps. Minimal example
covering multiple ecosystems:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"          # one block per ecosystem/directory
    directory: "/"
    schedule:
      interval: "weekly"              # daily | weekly | monthly
    open-pull-requests-limit: 10
    labels: ["dependencies"]
    groups:                            # batch related updates into one PR
      dev-dependencies:
        dependency-type: "development"
      production:
        dependency-type: "production"

  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"  # keep CI actions patched
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
```

Common ecosystems: `npm`, `pip`, `bundler`, `maven`, `gradle`, `gomod`, `cargo`,
`composer`, `nuget`, `docker`, `github-actions`, `terraform`, `pub`, `mix`.

Useful keys:
- `groups` — combine many bumps into a single reviewable PR (reduces noise).
- `ignore` — pin away noisy or breaking majors:
  ```yaml
  ignore:
    - dependency-name: "express"
      update-types: ["version-update:semver-major"]
  ```
- `allow`, `target-branch`, `reviewers`, `assignees`, `commit-message`,
  `rebase-strategy`, `versioning-strategy`, `registries` (private registries).

## 3. Triage Dependabot alerts

For each alert, decide and act:
1. **Severity & reachability** — is the vulnerable function actually used? Critical/High
   reachable code = patch now. Low severity in a dev-only or unreachable path = schedule.
2. **Fix available?** If a patched version exists, take the security-update PR. If not,
   apply a mitigation (config, input validation, feature flag) and track upstream.
3. **Dismiss with a reason** only when justified (not used / no fix / tolerable risk) —
   record the reason so the audit trail is clear.

## 4. Review & merge Dependabot PRs safely

- Read the PR's compatibility score and changelog/release notes.
- Ensure CI (tests + `sast-scanning`) passes on the PR branch before merge.
- For low-risk updates (patch bumps, grouped dev deps with green CI) enable
  auto-merge. Example workflow snippet:

  ```yaml
  # .github/workflows/dependabot-automerge.yml
  name: Dependabot auto-merge
  on: pull_request
  permissions:
    contents: write
    pull-requests: write
  jobs:
    automerge:
      if: github.actor == 'dependabot[bot]'
      runs-on: ubuntu-latest
      steps:
        - uses: dependabot/fetch-metadata@v2
          id: meta
        - if: steps.meta.outputs.update-type == 'version-update:semver-patch'
          run: gh pr merge --auto --squash "$PR_URL"
          env:
            PR_URL: ${{ github.event.pull_request.html_url }}
            GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  ```

  Never auto-merge majors or production-critical deps without human review.

## 5. Local / CI checks (no GitHub UI)

```bash
# Inspect alerts via GitHub CLI
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[] | {pkg:.dependency.package.name, sev:.security_advisory.severity, state:.state}'

# Ecosystem-native audits as a fast local complement
npm audit --omit=dev
pip-audit
```

## Remediation checklist

When a dependency CVE lands: confirm affected versions → bump to the patched release
(or remove/replace the dependency) → run tests + `sast-scanning` → verify the alert
closes → note any transitive deps that also need pinning.
