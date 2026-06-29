# NOTICE — attribution, licensing & sanitization

**Security Suite** is a curated combination of six independent, publicly available
upstream projects. All credit for the original skills, agents, tools, and content
belongs to their respective authors. This package re-organizes them into a single
Claude Code plugin; it does not claim original authorship of the upstream material.

## Upstream sources & authors

| Component | Author / Project | License | Bundled? | Upstream |
|---|---|---|---|---|
| 16 offensive skills + 6 subagents | Tri Luu — secskills | **MIT** | yes | https://github.com/trilwu/secskills |
| `owasp-security` skill | agamm — claude-code-owasp | **MIT** | yes | https://github.com/agamm/claude-code-owasp |
| 7 SecLists skills | Eyadkelleh — awesome-skills-security | **MIT** | yes (sanitized) | https://github.com/Eyadkelleh/awesome-skills-security |
| Code-review commands + hooks | Dietrich Gebert — ponytail | **MIT** | yes | https://github.com/DietrichGebert/ponytail |
| Wordlist/payload data | D. Miessler — SecLists | **MIT** | partial (text only) | https://github.com/danielmiessler/SecLists |
| `recon-automation` (wraps ReconForge) | ferasbusiness666 — ReconForge | **MIT** | no — installed at runtime | https://github.com/ferasbusiness666/ReconForge |
| `sast-scanning` (wraps MEDUSA) | Pantheon-Security — medusa | **AGPL-3.0** | no — installed at runtime | https://github.com/Pantheon-Security/medusa |
| `dependency-security` (Dependabot) | original content; references GitHub docs | MIT (this pkg) | n/a | https://github.com/dependabot |

Full license texts are in the [`licenses/`](licenses/) directory. The overall
licensing model is explained in [`LICENSE`](LICENSE).

**Licensing in one line:** everything *bundled* in this package is MIT (with each
author's copyright retained in `licenses/`); the two *wrapped* tools — ReconForge (MIT)
and **MEDUSA (AGPL-3.0)** — are not redistributed here but installed from their own
sources at runtime, so AGPL copyleft does not attach to this package.

The SecLists-derived skills ultimately reference Daniel Miessler's **SecLists**
(https://github.com/danielmiessler/SecLists), which is the canonical source for the
wordlists, payloads, and shell samples those skills curate.

Please consult each upstream repository for its exact license terms before
redistribution. Where a repo did not state a license explicitly, treat its content as
"all rights reserved" by the original author and use it only as permitted.

## Sanitization policy applied in this distribution

To keep this plugin safe to install and store, **live, runnable malicious artifacts
were deliberately excluded** from the SecLists-based skills:

- `security-webshells` — all runnable web-shell source files were removed (PHP/ASP/
  ASPX/JSP/CFM/WAR/EXE backdoors and reverse shells, the `laudanum` and `Vtiger` shell
  kits, `nc.exe`). Only the instructional `SKILL.md`, the benign `backdoor_list.txt`
  filename list, and licence/README files remain. See
  `security-suite/skills/security-webshells/NOTICE.md`.
- `security-payloads` — the EICAR test file, Flash `.swf` exploit, and `.zip` archives
  were removed. Benign filename-injection test payloads remain. See
  `security-suite/skills/security-payloads/NOTICE.md`.

The textual wordlists (usernames, passwords, fuzzing, patterns) and all instructional
`SKILL.md` content were preserved in full. Authorized testers who need the live samples
should obtain them from upstream SecLists and use them only in isolated labs against
authorized targets.

## Standalone tools

`recon-automation` and `sast-scanning` are **wrapper skills**: they install and drive
ReconForge and MEDUSA from their upstream sources (pip/git) rather than vendoring the
full source trees here. This keeps the plugin small and lets the tools update upstream.

## Responsible use

This suite is intended for lawful, authorized security work — penetration testing with
permission, red-team engagements under contract, defensive review of your own code, CTFs,
and security education. You are responsible for ensuring you have authorization for any
target you test.
