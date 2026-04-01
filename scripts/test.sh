#!/bin/bash
# test.sh
#
# Fires a test Jira assignment webhook to the Jarvis GitHub Actions workflow,
# bypassing Jira entirely. Use this to verify the full pipeline end-to-end.
#
# Usage:
#   ./scripts/test.sh                         # uses defaults
#   ./scripts/test.sh SOX-12345               # custom ticket key
#   ./scripts/test.sh SOX-12345 "My summary"  # custom key and summary

set -euo pipefail

TICKET_KEY="${1:-TEST-1}"
TICKET_SUMMARY="${2:-Test ticket: verify Jarvis notification pipeline}"
ASSIGNEE_EMAIL="${JARVIS_TEST_EMAIL:-${JIRA_EMAIL:-you@yourcompany.com}}"
JIRA_BASE_URL="${JIRA_URL:-https://yourcompany.atlassian.net}"
TICKET_URL="$JIRA_BASE_URL/browse/$TICKET_KEY"

# Detect repo from script location
JARVIS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GH_REPO=$(cd "$JARVIS_DIR" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "myronauditboard/jarvis")

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Jarvis Pipeline Test           ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Repo:     $GH_REPO"
echo "  Ticket:   $TICKET_KEY"
echo "  Summary:  $TICKET_SUMMARY"
echo "  Assignee: $ASSIGNEE_EMAIL"
echo "  Status:   To Do"
echo ""
echo "  Note: The workflow will re-validate the ticket via Jira API."
echo "  If $TICKET_KEY does not exist in Jira, the Slack/email step"
echo "  will be skipped (validation will fail). That's expected."
echo "  To test the full path, use a real ticket key."
echo ""
read -r -p "Fire the test webhook? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Firing repository_dispatch to $GH_REPO..."

gh api "repos/$GH_REPO/dispatches" \
  -f event_type=jira-ticket-assigned \
  -f "client_payload[ticket_key]=$TICKET_KEY" \
  -f "client_payload[summary]=$TICKET_SUMMARY" \
  -f "client_payload[ticket_url]=$TICKET_URL" \
  -f "client_payload[assignee_email]=$ASSIGNEE_EMAIL" \
  -f "client_payload[status]=To Do"

echo ""
echo "✓ Webhook fired."
echo ""
echo "Watch the run at:"
echo "  https://github.com/$GH_REPO/actions"
echo ""
echo "Tip: set JARVIS_TEST_EMAIL to override the assignee email"
echo "     (must match your JIRA_EMAIL secret for validation to pass)."
echo ""
