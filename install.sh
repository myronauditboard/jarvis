#!/bin/bash
# install.sh
#
# Jarvis setup wizard. Run once after cloning to configure credentials
# and get jarvis start working immediately.
#
# Usage: ./install.sh

set -euo pipefail

JARVIS_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$JARVIS_DIR")"
JARVISRC="$HOME/.jarvisrc"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Jarvis Setup Wizard            ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Jarvis installed at: $JARVIS_DIR"
echo ""

# =============================================================================
# Step 1: Prerequisites
# =============================================================================
echo "── Checking prerequisites ──────────────"
MISSING=0
for cmd in git curl jq gh claude; do
  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd"
  else
    echo "  ✗ $cmd (not found — please install it)"
    MISSING=1
  fi
done

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "Please install the missing tools above and re-run this script."
  exit 1
fi
echo ""

# =============================================================================
# Step 2: Check sibling repos
# =============================================================================
echo "── Checking sibling repos ──────────────"
for repo in auditboard-frontend auditboard-backend; do
  if [ -d "$PARENT_DIR/$repo" ]; then
    echo "  ✓ $repo found at $PARENT_DIR/$repo"
  else
    echo "  ⚠ $repo not found at $PARENT_DIR/$repo"
    echo "    Jarvis expects auditboard-frontend and auditboard-backend"
    echo "    to be siblings of this directory. Some features may not work."
  fi
done
echo ""

# =============================================================================
# Step 3: Jira credentials → saved to ~/.jarvisrc (enables jarvis start)
# =============================================================================
echo "── Jira credentials ────────────────────"
echo "  These are required for 'jarvis start' and will be saved to $JARVISRC."
echo ""

read -r -p "  JIRA_URL [https://auditboard.atlassian.net]: " JIRA_URL
JIRA_URL="${JIRA_URL:-https://auditboard.atlassian.net}"
read -r -p "  JIRA_EMAIL (e.g. you@auditboard.com): " JIRA_EMAIL
read -r -s -p "  JIRA_API_TOKEN (hidden — generate at id.atlassian.net): " JIRA_API_TOKEN
echo ""
echo ""

# Validate Jira connectivity
echo -n "  Testing Jira connectivity... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/myself")

if [ "$HTTP_CODE" = "200" ]; then
  echo "✓ Connected"
else
  echo "✗ Failed (HTTP $HTTP_CODE)"
  echo "  Check your JIRA_URL, JIRA_EMAIL, and JIRA_API_TOKEN and re-run."
  exit 1
fi
echo ""

# Save to ~/.jarvisrc
cat > "$JARVISRC" <<EOF
# Jarvis credentials — sourced by bin/jarvis at runtime
export JIRA_URL="$JIRA_URL"
export JIRA_EMAIL="$JIRA_EMAIL"
export JIRA_API_TOKEN="$JIRA_API_TOKEN"
EOF
chmod 600 "$JARVISRC"
echo "  ✓ Credentials saved to $JARVISRC (mode 600)"
echo ""

# =============================================================================
# Step 4: Add jarvis to PATH
# =============================================================================
echo "── Adding jarvis to PATH ───────────────"

SHELL_RC=""
if [[ "$SHELL" == */zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

JARVIS_BIN_LINE="export PATH=\"$JARVIS_DIR/bin:\$PATH\""

if [[ -n "$SHELL_RC" ]]; then
  if grep -qF "$JARVIS_DIR/bin" "$SHELL_RC" 2>/dev/null; then
    echo "  ✓ jarvis already in PATH ($SHELL_RC)"
  else
    echo "" >> "$SHELL_RC"
    echo "# Jarvis CLI" >> "$SHELL_RC"
    echo "$JARVIS_BIN_LINE" >> "$SHELL_RC"
    echo "  ✓ Added to $SHELL_RC"
    echo "  Run: source $SHELL_RC  (or open a new terminal)"
  fi
else
  echo "  Could not detect shell config. Add this to your shell profile manually:"
  echo "  $JARVIS_BIN_LINE"
fi
echo ""

# =============================================================================
# Step 5: GitHub Secrets (optional — needed for cloud notifications)
# =============================================================================
echo "── GitHub Secrets (optional) ───────────"
echo "  GitHub Secrets power the cloud notification workflow."
echo "  Skip any secret by pressing Enter — you can set them later."
echo ""

GH_REPO=$(cd "$JARVIS_DIR" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [[ -z "$GH_REPO" ]]; then
  echo "  Could not detect GitHub repo. Make sure gh is authenticated and this is a GitHub repo."
  read -r -p "  Enter repo manually (e.g. myronauditboard/jarvis): " GH_REPO
fi
echo "  Repo: $GH_REPO"
echo ""

# Upload a secret only if a value was provided
set_secret_optional() {
  local name="$1"
  local description="$2"
  local hint="$3"
  local sensitive="${4:-true}"

  echo "  $name — $description"
  echo "  ($hint)"

  local value=""
  if [ "$sensitive" = "true" ]; then
    read -r -s -p "  Value (hidden, Enter to skip): " value
    echo ""
  else
    read -r -p "  Value (Enter to skip): " value
  fi

  if [[ -z "$value" ]]; then
    echo "  — skipped"
  else
    gh secret set "$name" --body "$value" --repo "$GH_REPO"
    echo "  ✓ $name saved"
  fi
  echo ""
}

# Upload Jira secrets to GitHub (so the cloud workflow can validate tickets)
echo "  Uploading Jira credentials to GitHub Secrets..."
gh secret set "JIRA_URL"       --body "$JIRA_URL"       --repo "$GH_REPO" 2>/dev/null && echo "  ✓ JIRA_URL"       || echo "  ⚠ JIRA_URL upload failed (you can set it manually)"
gh secret set "JIRA_EMAIL"     --body "$JIRA_EMAIL"     --repo "$GH_REPO" 2>/dev/null && echo "  ✓ JIRA_EMAIL"     || echo "  ⚠ JIRA_EMAIL upload failed"
gh secret set "JIRA_API_TOKEN" --body "$JIRA_API_TOKEN" --repo "$GH_REPO" 2>/dev/null && echo "  ✓ JIRA_API_TOKEN" || echo "  ⚠ JIRA_API_TOKEN upload failed"
echo ""

set_secret_optional "SLACK_BOT_TOKEN" \
  "Slack bot token for DM notifications" \
  "See docs/slack-app-setup.md — skip if not set up yet" \
  "true"

set_secret_optional "SLACK_USER_ID" \
  "Your Slack member ID" \
  "Slack → your profile → ··· → Copy member ID" \
  "false"

echo "  ── Email fallback ──"
set_secret_optional "SMTP_SERVER"   "SMTP hostname"          "e.g. smtp.gmail.com"    "false"
set_secret_optional "SMTP_USERNAME" "SMTP sender address"    "e.g. you@gmail.com"     "false"
set_secret_optional "SMTP_PASSWORD" "SMTP app password"      "See docs/email-notifications-setup.md" "true"
set_secret_optional "NOTIFY_EMAIL"  "Notification recipient" "e.g. you@yourcompany.com" "false"

# =============================================================================
# Done
# =============================================================================
echo "╔══════════════════════════════════════╗"
echo "║         Setup Complete!              ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  'jarvis start' is ready to use now."
echo ""
echo "  Cloud notifications (Slack/email) need the Jira Automation rule:"
echo "  See: $JARVIS_DIR/docs/jira-automation-setup.md"
echo ""
echo "  Test the notification pipeline anytime:"
echo "  ./scripts/test.sh"
echo ""
