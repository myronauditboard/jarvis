# Jarvis

Jarvis watches Jira for ticket assignments and notifies you instantly via Slack — 24/7, no Mac required.

When a Jira ticket is assigned to you in **To Do** status, Jarvis sends you a Slack DM within seconds.

## How It Works

```
Jira assigns a ticket to you
  → Jira Automation fires a webhook to GitHub
    → GitHub Actions validates the ticket via Jira API
      → Slack DM sent to you (falls back to email if Slack is unavailable)
```

Everything runs in GitHub's cloud — free, always on.

## Prerequisites

- A GitHub account with access to this repo
- Jira project access with permission to create Automation rules
- A Slack app with `chat:write` scope installed to your workspace
- The GitHub CLI (`gh`) installed locally

### SATL Skill Dependencies

`jarvis start` depends on the following files being present in your sibling repos. These are installed by the SATL toolchain — Jarvis will not work without them.

| File | Repo | Purpose |
|------|------|---------|
| `.claude/commands/satl-start-jira-work-command-u-myronauditboard.md` | `auditboard-backend` | Orchestrates the full backend implementation workflow |
| `.claude/commands/satl-start-jira-work-command-u-myronauditboard.md` | `auditboard-frontend` | Orchestrates the full frontend implementation workflow |
| `.claude/rules/satl-indicators-backend-rule-u-myronauditboard.md` | `auditboard-backend` | Defines what constitutes backend work for a ticket |
| `.claude/rules/satl-indicators-frontend-rule-u-myronauditboard.md` | `auditboard-frontend` | Defines what constitutes frontend work for a ticket |

If these files are missing, `jarvis start` will warn about missing indicators and may not correctly determine which repos need changes.

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

1. [Slack App Setup](docs/slack-app-setup.md) — create the bot that sends you DMs *(optional — email is used as fallback)*
2. [Email Notifications Setup](docs/email-notifications-setup.md) — configure SMTP fallback
3. [GitHub Secrets Setup](docs/github-secrets-setup.md) — store credentials securely
4. [Jira Automation Setup](docs/jira-automation-setup.md) — configure the Jira webhook

## Local CLI — `jarvis start`

After receiving a notification, run:

```bash
jarvis start SOX-12345
```

Jarvis will:
1. Fetch the ticket from Jira
2. Read indicator files from `auditboard-backend` and `auditboard-frontend`
3. Ask Claude which repo(s) need changes
4. If both repos need changes: create an orchestration plan defining the API contract
5. Run the backend agent (with the plan as context)
6. Run the frontend agent (with the plan + backend PR URL as context)

Logs are saved to `jarvis/logs/`. Orchestration plans are saved to `jarvis/plans/` (gitignored).

## Testing

Trigger a test workflow run without touching Jira:

```bash
./scripts/test.sh              # uses TEST-1 with defaults
./scripts/test.sh SOX-12345    # uses a real ticket key
```

Or manually:
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
  .github/workflows/jira-assigned.yml   # GitHub Actions workflow (with deduplication)
  bin/jarvis                            # Local CLI
  scripts/
    notify-slack.sh                     # Slack DM sender
    test.sh                             # Fire a test webhook
  docs/                                 # Setup guides
  install.sh                            # Setup wizard
  plans/                                # Cross-repo orchestration plans (gitignored)
  logs/                                 # Agent run logs (gitignored)
```
