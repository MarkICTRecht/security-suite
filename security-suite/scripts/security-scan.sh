#!/usr/bin/env bash
# =============================================================================
# Security Suite — full-codebase scan orchestrator
# Runs the suite's DEFENSIVE checks against one project and writes a single
# consolidated Markdown report:
#   1. MEDUSA          — multi-language SAST (70+ linters, secrets, config)
#   2. Dependencies    — npm / pip / go / bundler audits (supply chain)
#   3. Secrets sweep   — high-signal credential/key regexes (security-patterns)
#   4. Dependabot      — supply-chain hygiene check (.github/dependabot.yml)
#
# Usage:
#   security-scan.sh <path|git-url> [--quick] [--no-install]
#
# Examples:
#   security-scan.sh .                                   # current dir, full
#   security-scan.sh ~/projects/myapp --quick            # fast pass
#   security-scan.sh https://github.com/me/myrepo.git    # clone & scan
#
# Env:
#   SECSCAN_OUT=/path   override report output dir (default ./security-reports/<ts>)
#
# Authorized/defensive use only — scan code you own or maintain.
# =============================================================================
set -uo pipefail

TARGET="${1:-.}"; shift || true
QUICK=""; INSTALL=1
for a in "$@"; do
  case "$a" in
    --quick) QUICK="--quick" ;;
    --no-install) INSTALL=0 ;;
  esac
done

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
say(){ printf '%s\n' "$*"; }
hdr(){ printf '\n%s== %s ==%s\n' "$c_dim" "$*" "$c_off"; }

# --- resolve target (git url -> shallow clone) -------------------------------
CLEANUP=""
case "$TARGET" in
  http://*|https://*|git@*)
    TMP="$(mktemp -d)"; WORKDIR="$TMP/repo"
    hdr "Cloning $TARGET"
    git clone --depth 1 "$TARGET" "$WORKDIR" >/dev/null 2>&1 || { say "${c_red}Clone failed${c_off}"; exit 1; }
    CLEANUP="$TMP"
    ;;
  *)
    WORKDIR="$(cd "$TARGET" 2>/dev/null && pwd)" || { say "${c_red}Path not found: $TARGET${c_off}"; exit 1; }
    ;;
esac

TS="$(date +%Y%m%d-%H%M%S)"
OUT="${SECSCAN_OUT:-$PWD/security-reports/$TS}"
mkdir -p "$OUT"
REPORT="$OUT/REPORT.md"
PROJECT_NAME="$(basename "$WORKDIR")"

have(){ command -v "$1" >/dev/null 2>&1; }
pipx_or_pip(){ pip install "$1" --break-system-packages >/dev/null 2>&1 || pip3 install "$1" --break-system-packages >/dev/null 2>&1; }

{
  echo "# Security scan report — \`$PROJECT_NAME\`"
  echo
  echo "- **Target:** \`$WORKDIR\`"
  echo "- **Date:** $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "- **Mode:** ${QUICK:-full}"
  echo "- **Engine:** Security Suite \`security-scan.sh\`"
  echo
  echo "> Defensive scan. Triage findings with the \`owasp-security\` skill and remediate"
  echo "> highest severity first. False positives should be documented, not ignored."
  echo
  echo "---"
} > "$REPORT"

SUMMARY_SAST="not run"; SUMMARY_DEPS="not run"; SUMMARY_SECRETS="0"; SUMMARY_DEPABOT="missing"
CRIT=0; HIGH=0; MED=0; LOW=0; SAST_RAN=0; SECRET_HITS=0; DEPABOT_BOOL=false
DEP_ECO=()

# --- 1. MEDUSA SAST ----------------------------------------------------------
hdr "1/4  MEDUSA SAST"
if ! have medusa && [ "$INSTALL" = 1 ]; then say "Installing medusa-security..."; pipx_or_pip medusa-security; fi
if have medusa; then
  ( cd "$WORKDIR" && medusa scan . $QUICK ) > "$OUT/medusa.txt" 2>&1 || true
  # try to locate the JSON report medusa writes
  MJSON="$(find "$WORKDIR/.medusa/reports" -name '*.json' 2>/dev/null | head -1)"
  [ -n "$MJSON" ] && cp "$MJSON" "$OUT/medusa.json" 2>/dev/null || true
  SAST_RAN=1
  CRIT=$(grep -iEo 'CRITICAL[: ]+[0-9]+' "$OUT/medusa.txt" | grep -Eo '[0-9]+' | tail -1); CRIT=${CRIT:-0}
  HIGH=$(grep -iEo 'HIGH[: ]+[0-9]+'     "$OUT/medusa.txt" | grep -Eo '[0-9]+' | tail -1); HIGH=${HIGH:-0}
  MED=$(grep -iEo 'MEDIUM[: ]+[0-9]+'    "$OUT/medusa.txt" | grep -Eo '[0-9]+' | tail -1); MED=${MED:-0}
  LOW=$(grep -iEo 'LOW[: ]+[0-9]+'       "$OUT/medusa.txt" | grep -Eo '[0-9]+' | tail -1); LOW=${LOW:-0}
  SUMMARY_SAST="CRITICAL=${CRIT} HIGH=${HIGH} MEDIUM=${MED} LOW=${LOW} (see medusa.txt)"
  {
    echo; echo "## 1. SAST — MEDUSA"; echo
    echo "\`\`\`"; tail -40 "$OUT/medusa.txt"; echo "\`\`\`"
    echo; echo "_Full output: \`medusa.txt\` · JSON: \`medusa.json\`_"
  } >> "$REPORT"
else
  SUMMARY_SAST="skipped (medusa not installed)"
  { echo; echo "## 1. SAST — MEDUSA"; echo; echo "> Skipped — \`medusa\` not available. Install: \`pip install medusa-security\`"; } >> "$REPORT"
fi

# --- 2. Dependency / supply-chain audits ------------------------------------
hdr "2/4  Dependency audits"
DEP_LINES=""
add_dep(){ DEP_LINES+="$1"$'\n'; }
cd "$WORKDIR" || exit 1
if [ -f package.json ]; then
  DEP_ECO+=("npm")
  if have npm; then npm audit --omit=dev > "$OUT/npm-audit.txt" 2>&1 || true
    V=$(grep -Eo '[0-9]+ vulnerabilities' "$OUT/npm-audit.txt" | tail -1); add_dep "- **npm**: ${V:-see npm-audit.txt}"
  else add_dep "- **npm**: package.json found but npm not installed"; fi
fi
if compgen -G "requirements*.txt" >/dev/null 2>&1 || [ -f Pipfile ] || [ -f pyproject.toml ] || [ -f poetry.lock ]; then
  DEP_ECO+=("pip")
  if ! have pip-audit && [ "$INSTALL" = 1 ]; then pipx_or_pip pip-audit; fi
  if have pip-audit; then pip-audit -f markdown > "$OUT/pip-audit.md" 2>&1 || pip-audit > "$OUT/pip-audit.md" 2>&1 || true
    add_dep "- **pip-audit**: see pip-audit.md"
  else add_dep "- **pip**: python deps found but pip-audit not installed"; fi
fi
if [ -f go.mod ]; then
  DEP_ECO+=("go")
  if have govulncheck; then govulncheck ./... > "$OUT/govulncheck.txt" 2>&1 || true; add_dep "- **govulncheck**: see govulncheck.txt"
  else add_dep "- **go**: go.mod found; install govulncheck for analysis"; fi
fi
if [ -f Gemfile.lock ]; then
  DEP_ECO+=("ruby")
  if have bundle-audit; then bundle-audit check --update > "$OUT/bundler-audit.txt" 2>&1 || true; add_dep "- **bundler-audit**: see bundler-audit.txt"
  else add_dep "- **ruby**: Gemfile.lock found; install bundler-audit"; fi
fi
[ -z "$DEP_LINES" ] && DEP_LINES="- No recognized dependency manifests found."
SUMMARY_DEPS="$(printf '%s' "$DEP_LINES" | grep -c '^- ' )  ecosystem(s)"
{ echo; echo "## 2. Dependencies / supply chain"; echo; printf '%s\n' "$DEP_LINES"; } >> "$REPORT"

# --- 3. Secrets / sensitive-data sweep --------------------------------------
hdr "3/4  Secrets sweep"
GREP="grep -rInE"; have rg && GREP="rg -nI --no-heading -e"
SECRETS_FILE="$OUT/secrets.txt"; : > "$SECRETS_FILE"
# high-signal patterns (subset of the security-patterns skill)
patterns=(
  'AKIA[0-9A-Z]{16}'                                  # AWS access key id
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'    # AWS secret
  '-----BEGIN (RSA|EC|OPENSSH|DSA|PGP) PRIVATE KEY-----' # private keys
  'gh[pousr]_[A-Za-z0-9]{36,}'                        # GitHub tokens
  'xox[baprs]-[0-9A-Za-z-]{10,}'                      # Slack tokens
  'AIza[0-9A-Za-z_\-]{35}'                            # Google API key
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' # JWT
  '(password|passwd|pwd|secret|api[_-]?key|token)\s*[:=]\s*["'"'"'][^"'"'"']{6,}["'"'"']' # inline creds
)
EXCL='--glob=!**/node_modules/** --glob=!**/.git/** --glob=!**/vendor/** --glob=!**/dist/** --glob=!**/build/**'
for p in "${patterns[@]}"; do
  if have rg; then rg -nI --no-heading $EXCL -e "$p" . >> "$SECRETS_FILE" 2>/dev/null || true
  else grep -rInE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build "$p" . >> "$SECRETS_FILE" 2>/dev/null || true; fi
done
SECRET_HITS=$(wc -l < "$SECRETS_FILE" | tr -d ' ')
SUMMARY_SECRETS="$SECRET_HITS"
{
  echo; echo "## 3. Secrets / sensitive data"; echo
  if [ "$SECRET_HITS" -gt 0 ]; then
    echo "⚠️ **$SECRET_HITS potential secret(s) matched.** Review \`secrets.txt\` — confirm true positives, rotate any real credential, and move it to a secret manager / env var."
    echo; echo "\`\`\`"; head -40 "$SECRETS_FILE"; echo "\`\`\`"
  else echo "✅ No high-signal secret patterns matched."; fi
} >> "$REPORT"

# --- 4. Dependabot / supply-chain hygiene -----------------------------------
hdr "4/4  Dependabot hygiene"
if [ -f .github/dependabot.yml ] || [ -f .github/dependabot.yaml ]; then
  SUMMARY_DEPABOT="present"; DEPABOT_BOOL=true
  { echo; echo "## 4. Dependabot hygiene"; echo; echo "✅ \`.github/dependabot.yml\` present — automated dependency updates configured."; } >> "$REPORT"
else
  SUMMARY_DEPABOT="missing"
  { echo; echo "## 4. Dependabot hygiene"; echo; echo "⚠️ No \`.github/dependabot.yml\`. Add one (see the \`dependency-security\` skill) to get automated CVE patches and version updates."; } >> "$REPORT"
fi

# --- summary header (prepend) ------------------------------------------------
{
  echo; echo "---"; echo; echo "## At a glance"; echo
  echo "| Check | Result |"
  echo "|---|---|"
  echo "| SAST (MEDUSA) | $SUMMARY_SAST |"
  echo "| Dependencies | $SUMMARY_DEPS |"
  echo "| Secret matches | $SUMMARY_SECRETS |"
  echo "| Dependabot config | $SUMMARY_DEPABOT |"
  echo
  echo "_Next: open this report in Claude Code and run the \`owasp-security\` skill to triage and get fixes._"
} >> "$REPORT"

# --- machine-readable summary + HTML dashboard ------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$OUT" "$PROJECT_NAME" "$WORKDIR" "$QUICK" "$SAST_RAN" "$CRIT" "$HIGH" "$MED" "$LOW" "$SECRET_HITS" "$DEPABOT_BOOL" "${DEP_ECO[*]:-}" <<'PY' 2>/dev/null || true
import json,sys,pathlib
out=pathlib.Path(sys.argv[1])
sample=[]
sf=out/"secrets.txt"
if sf.exists(): sample=[l.rstrip("\n") for l in sf.read_text(errors="replace").splitlines() if l.strip()][:25]
eco=[e for e in sys.argv[12].split() if e]
data={
 "project":sys.argv[2],"target":sys.argv[3],
 "date":__import__("datetime").datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
 "mode": sys.argv[4] or "full",
 "sast":{"ran":sys.argv[5]=="1","critical":int(sys.argv[6]),"high":int(sys.argv[7]),"medium":int(sys.argv[8]),"low":int(sys.argv[9])},
 "secrets":{"count":int(sys.argv[10]),"sample":sample},
 "dependencies":eco,
 "dependabot": sys.argv[11]=="true",
}
(out/"summary.json").write_text(json.dumps(data,indent=2))
PY

HTML_OK=""
if have python3 && [ -f "$OUT/summary.json" ]; then
  python3 "$SCRIPT_DIR/render_report.py" "$OUT" >/dev/null 2>&1 && HTML_OK="$OUT/report.html"
fi

[ -n "$CLEANUP" ] && rm -rf "$CLEANUP" 2>/dev/null || true

hdr "Done"
say "${c_grn}Report (Markdown):${c_off} $REPORT"
[ -n "$HTML_OK" ] && say "${c_grn}Report (HTML dashboard):${c_off} $HTML_OK"
say "SAST: $SUMMARY_SAST | Secrets: $SUMMARY_SECRETS | Dependabot: $SUMMARY_DEPABOT"
