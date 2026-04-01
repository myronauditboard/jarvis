# Jira Automation Rule Setup

This guide walks you through creating the Jira Automation rule that fires a webhook to Jarvis when a ticket is assigned to you.

## Prerequisites

- Admin or project-admin access to your Jira project (or global automation access)
- A **GitHub Personal Access Token (PAT)** with `repo` scope for `myronauditboard/jarvis`
  - Create at: https://github.com/settings/tokens (use a **classic** PAT)
  - Required scope: `repo` (for triggering `repository_dispatch`)

## Create the Rule

Navigate to your Jira project → **Project Settings** → **Automation** → **Create rule**

(For global rules covering all projects: Jira Settings → System → Automation)

---

### Trigger: Issue assigned

Select **"Field value changed"** as the trigger.

- **Fields to monitor:** Assignee
- Leave other options as default

---

### Condition: Issue matches JQL

Add a condition: **"Issue matches"**

```
assignee = "your-email@yourcompany.com" AND status = "To Do"
```

This ensures the rule only continues when the ticket is both assigned to you **and** in To Do status.

---

### Action: Send web request

Add an action: **"Send web request"**

**URL:**
```
https://api.github.com/repos/myronauditboard/jarvis/dispatches
```

**Method:** `POST`

**Headers:**

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer {{YOUR_GITHUB_PAT}}` |
| `Accept` | `application/vnd.github+json` |
| `X-GitHub-Api-Version` | `2022-11-28` |
| `Content-Type` | `application/json` |

> Store your PAT in Jira's **Secret** store and reference it as `{{#secretAlias}}GITHUB_PAT{{/secretAlias}}` in the Authorization header value.

**Body (Custom data):**
```json
{
  "event_type": "jira-ticket-assigned",
  "client_payload": {
    "ticket_key": "{{issue.key}}",
    "summary": "{{issue.summary.jsonEncode}}",
    "ticket_url": "https://YOUR-DOMAIN.atlassian.net/browse/{{issue.key}}",
    "assignee_email": "{{issue.assignee.email}}",
    "status": "{{issue.status.name}}"
  }
}
```

Replace `YOUR-DOMAIN` with your Atlassian subdomain.

---

## Save and Enable the Rule

1. Name the rule: `Jarvis — Ticket Assigned Notification`
2. Click **Save**
3. Toggle the rule **on**

---

## Testing the Rule

1. Assign a Jira ticket to yourself with status **To Do**
2. Check the rule's **Audit log** (within the Automation page) — it should show a successful webhook call
3. Check GitHub Actions at: https://github.com/myronauditboard/jarvis/actions
4. You should receive a Slack DM within seconds

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| Jira audit log shows 401 | GitHub PAT is invalid or expired |
| Jira audit log shows 404 | Repo name is wrong or PAT lacks `repo` scope |
| GitHub Action runs but no Slack DM | `SLACK_BOT_TOKEN` secret is missing or the token is invalid |
| GitHub Action skips the Slack step | Ticket validation failed — check that assignee email and status match exactly |
| Jira audit log shows 422 | JSON body is malformed — check Smart Values and `jsonEncode` usage |
