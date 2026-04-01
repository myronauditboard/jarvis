# GitHub Secrets Setup

Jarvis uses GitHub Secrets to store credentials securely. They are encrypted at rest and only exposed to the GitHub Actions workflow at runtime — never logged or visible in the UI.

## Where to Add Secrets

Go to: **https://github.com/myronauditboard/jarvis/settings/secrets/actions**

Click **New repository secret** for each of the following.

---

## Required Secrets

### `JIRA_URL`
Your Jira instance base URL.

**Example:** `https://yourcompany.atlassian.net`

No trailing slash.

---

### `JIRA_EMAIL`
The email address of the Jira account whose assignments Jarvis should watch.

**Example:** `you@yourcompany.com`

This is also the account whose API token you'll use below.

---

### `JIRA_API_TOKEN`
An API token for your Jira account.

1. Go to: https://id.atlassian.net/manage-profile/security/api-tokens
2. Click **Create API token**
3. Give it a label like `Jarvis`
4. Copy the token immediately — it won't be shown again

---

### `SLACK_BOT_TOKEN`
The bot token for your Jarvis Slack app.

Starts with `xoxb-`. See [slack-app-setup.md](./slack-app-setup.md) for how to create one.

---

## Setting Secrets via CLI

If you prefer, you can set secrets using the GitHub CLI after running `./install.sh`:

```bash
gh secret set JIRA_URL        --body "https://yourcompany.atlassian.net" --repo myronauditboard/jarvis
gh secret set JIRA_EMAIL      --body "you@yourcompany.com"               --repo myronauditboard/jarvis
gh secret set JIRA_API_TOKEN  --body "your-api-token"                    --repo myronauditboard/jarvis
gh secret set SLACK_BOT_TOKEN --body "xoxb-your-token"                   --repo myronauditboard/jarvis
```

## Verifying Secrets Are Set

```bash
gh secret list --repo myronauditboard/jarvis
```

This shows secret names (not values) — you should see all four listed.
