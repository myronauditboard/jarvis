# Jarvis

Jarvis watches Jira for ticket assignments and notifies you instantly via Slack — 24/7, no Mac required.

When a Jira ticket is assigned to you in **To Do** status, Jarvis sends you a Slack DM within seconds.

## How It Works

```
Jira assigns a ticket to you
  → Jira Automation fires a webhook to GitHub
    → GitHub Actions validates the ticket via Jira API
      → Slack DM sent to you with ticket details
```

Everything runs in GitHub's cloud — free, always on.

## Prerequisites

- A GitHub account with access to this repo
- Jira project access with permission to create Automation rules
- A Slack app with `chat:write` scope installed to your workspace
- The GitHub CLI (`gh`) installed locally

## Quickstart

Clone Jarvis as a sibling of your `auditboard-frontend` and `auditboard-backend` directories:

```bash
cd /path/to/your/dev/folder
git clone https://github.com/myronauditboard/jarvis
cd jarvis
./install.sh
```

The setup wizard will:
- Check prerequisites
- Validate sibling repo locations
- Prompt for and securely store your credentials as GitHub Secrets
- Test your Jira connectivity
- Print next steps

## Setup Guides

After running `./install.sh`, follow these guides in order:

1. [Slack App Setup](docs/slack-app-setup.md) — create the bot that sends you DMs
2. [GitHub Secrets Setup](docs/github-secrets-setup.md) — store credentials securely
3. [Jira Automation Setup](docs/jira-automation-setup.md) — configure the Jira webhook

## Testing

Trigger a test workflow run without touching Jira:

```bash
gh api repos/myronauditboard/jarvis/dispatches \
  -f event_type=jira-ticket-assigned \
  -f client_payload[ticket_key]=SOX-12345 \
  -f client_payload[summary]="My test ticket" \
  -f client_payload[ticket_url]="https://yourcompany.atlassian.net/browse/SOX-12345" \
  -f client_payload[assignee_email]="you@yourcompany.com" \
  -f client_payload[status]="To Do"
```

Then watch the run: https://github.com/myronauditboard/jarvis/actions

## Directory Layout

```
jarvis/
  .github/workflows/jira-assigned.yml   # GitHub Actions workflow
  scripts/notify-slack.sh               # Slack DM sender
  docs/                                 # Setup guides
  install.sh                            # Setup wizard
```
