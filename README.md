# Jarvis

Jarvis is a local CLI that turns a Jira ticket key into a coordinated implementation across `auditboard-backend` and `auditboard-frontend`.

Given a ticket, Jarvis fetches it from Jira, figures out which repo(s) need changes, and — when both do — writes an orchestration plan defining the API contract before running the backend and frontend agents in sequence.

## Prerequisites

- `claude` CLI in PATH (Claude Code)
- `gh` CLI in PATH, authenticated
- `jq` in PATH
- `auditboard-backend` and `auditboard-frontend` checked out as siblings of this repo
- Jira credentials (`JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`) exported in your shell or `~/.jarvisrc`

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

The setup wizard will check prerequisites, validate sibling repo locations, prompt for and store your Jira credentials, and test connectivity.

## Usage

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

## Directory Layout

```
jarvis/
  bin/jarvis        # Local CLI
  install.sh        # Setup wizard
  plans/            # Cross-repo orchestration plans (gitignored)
  logs/             # Agent run logs (gitignored)
```
