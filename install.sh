#!/bin/bash
# install.sh
#
# Jarvis setup wizard. Run once after cloning to configure GitHub Secrets
# and validate your environment.
#
# Usage: ./install.sh

set -euo pipefail

JARVIS_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$JARVIS_DIR")"

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
for cmd in git curl jq gh; do
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
# Step 3: GitHub repo
# =============================================================================
echo "── GitHub repo ─────────────────────────"
read -r -p "GitHub repo for Jarvis [myronauditboard/jarvis]: " GH_REPO
GH_REPO="${GH_REPO:-myronauditboard/jarvis}"
echo ""

# =============================================================================
# Step 4: GitHub Secrets
# =============================================================================
echo "── GitHub Secrets ──────────────────────"
echo "We'll store your credentials as encrypted GitHub Secrets."
echo "They are never written to disk or shown in logs."
echo ""

set_secret() {
  local name="$1"
  local description="$2"
  local hint="$3"
  local sensitive="${4:-true}"

  echo "  $name"
  echo "  $description"
  echo "  ($hint)"

  if [ "$sensitive" = "true" ]; then
    read -r -s -p "  Value (hidden): " VALUE
    echo ""
  else
    read -r -p "  Value: " VALUE
  fi

  gh secret set "$name" --body "$VALUE" --repo "$GH_REPO"
  echo "  ✓ $name saved"
  echo ""
}

set_secret "JIRA_URL" \
  "Your Jira base URL" \
  "e.g. https://yourcompany.atlassian.net" \
  "false"

set_secret "JIRA_EMAIL" \
  "The email address of your Jira account" \
  "e.g. you@yourcompany.com" \
  "false"

set_secret "JIRA_API_TOKEN" \
  "Your Jira API token" \
  "Generate at: https://id.atlassian.net/manage-profile/security/api-tokens" \
  "true"

set_secret "SLACK_BOT_TOKEN" \
  "Your Slack bot token (xoxb-...) — leave blank to skip, email will be used instead" \
  "See docs/slack-app-setup.md for how to create one" \
  "true"

set_secret "SLACK_USER_ID" \
  "Your Slack user ID — Jarvis will DM this user" \
  "Find it in Slack: click your profile → ··· menu → Copy member ID" \
  "false"

echo "── Email fallback (used when Slack is unavailable) ─"
echo "  See docs/email-notifications-setup.md for setup details."
echo ""

set_secret "SMTP_SERVER" \
  "SMTP server hostname" \
  "e.g. smtp.gmail.com" \
  "false"

set_secret "SMTP_USERNAME" \
  "SMTP username / sender email address" \
  "e.g. you@gmail.com" \
  "false"

set_secret "SMTP_PASSWORD" \
  "SMTP password or app password" \
  "For Gmail: generate at https://myaccount.google.com/apppasswords" \
  "true"

set_secret "NOTIFY_EMAIL" \
  "Email address to deliver Jarvis notifications to" \
  "e.g. you@yourcompany.com" \
  "false"

# =============================================================================
# Step 5: Validate Jira connectivity
# =============================================================================
echo "── Validating Jira connectivity ────────"

read -r -p "  Re-enter JIRA_URL to test connectivity: " TEST_JIRA_URL
read -r -p "  Re-enter JIRA_EMAIL: " TEST_EMAIL
read -r -s -p "  Re-enter JIRA_API_TOKEN (hidden): " TEST_TOKEN
echo ""

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "$TEST_EMAIL:$TEST_TOKEN" \
  "$TEST_JIRA_URL/rest/api/3/myself")

if [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ Jira connection successful"
else
  echo "  ✗ Jira connection failed (HTTP $HTTP_CODE)"
  echo "    Check your JIRA_URL, JIRA_EMAIL, and JIRA_API_TOKEN."
fi
echo ""

# =============================================================================
# Done
# =============================================================================
echo "╔══════════════════════════════════════╗"
echo "║         Setup Complete!              ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Set up your Slack app (if you haven't):"
echo "     $JARVIS_DIR/docs/slack-app-setup.md"
echo ""
echo "  2. Configure your Jira Automation rule:"
echo "     $JARVIS_DIR/docs/jira-automation-setup.md"
echo ""
echo "  3. Test the workflow end-to-end:"
echo "     gh api repos/$GH_REPO/dispatches \\"
echo "       -f event_type=jira-ticket-assigned \\"
echo "       -f client_payload[ticket_key]=TEST-1 \\"
echo "       -f client_payload[summary]=\"Test ticket\" \\"
echo "       -f client_payload[ticket_url]=\"https://example.atlassian.net/browse/TEST-1\" \\"
echo "       -f client_payload[assignee_email]=\"you@yourcompany.com\" \\"
echo "       -f client_payload[status]=\"To Do\""
echo ""
echo "  Then watch the run at: https://github.com/$GH_REPO/actions"
echo ""
