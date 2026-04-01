#!/bin/bash
# notify-slack.sh
#
# Sends a Slack DM to the Jarvis owner when a Jira ticket is assigned.
#
# Required environment variables (set by jira-assigned.yml):
#   SLACK_BOT_TOKEN  — xoxb- bot token with chat:write scope
#   TICKET_KEY       — e.g. SOX-84649
#   TICKET_SUMMARY   — ticket title
#   TICKET_URL       — full URL to the Jira ticket

set -euo pipefail

: "${SLACK_BOT_TOKEN:?SLACK_BOT_TOKEN is required}"
: "${TICKET_KEY:?TICKET_KEY is required}"
: "${TICKET_SUMMARY:?TICKET_SUMMARY is required}"
: "${TICKET_URL:?TICKET_URL is required}"

SLACK_USER_ID="U07DM3M078R"

# Build the Slack Block Kit payload using jq --arg to safely handle any
# special characters in the ticket summary (quotes, backslashes, etc.)
PAYLOAD=$(jq -n \
  --arg channel   "$SLACK_USER_ID" \
  --arg key       "$TICKET_KEY" \
  --arg summary   "$TICKET_SUMMARY" \
  --arg url       "$TICKET_URL" \
  '{
    channel: $channel,
    text: ("New Jira ticket assigned: " + $key),
    blocks: [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: ("*New ticket assigned to you* :jira:\n*<" + $url + "|" + $key + ">* — " + $summary)
        }
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: ("To start work locally, run:\n```jarvis start " + $key + "```")
        }
      }
    ]
  }')

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$PAYLOAD" \
  "https://slack.com/api/chat.postMessage")

OK=$(echo "$RESPONSE" | jq -r '.ok')

if [ "$OK" != "true" ]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error')
  echo "Slack API error: ${ERROR}"
  exit 1
fi

echo "Slack DM sent successfully for ${TICKET_KEY}."
