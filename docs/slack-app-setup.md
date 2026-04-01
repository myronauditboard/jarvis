# Slack App Setup

Jarvis sends you a Slack DM when a Jira ticket is assigned to you. This requires a Slack bot with the `chat:write` permission.

## Steps

### 1. Create a Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name it `Jarvis` and select your Slack workspace
4. Click **Create App**

### 2. Add Permissions

1. In the left sidebar, click **OAuth & Permissions**
2. Scroll to **Scopes** → **Bot Token Scopes**
3. Click **Add an OAuth Scope** and add: `chat:write`

### 3. Install the App

1. Scroll up to **OAuth Tokens for Your Workspace**
2. Click **Install to Workspace**
3. Review and click **Allow**
4. Copy the **Bot User OAuth Token** — it starts with `xoxb-`

### 4. Add the Token to Jarvis

When running `./install.sh`, paste the `xoxb-` token when prompted for `SLACK_BOT_TOKEN`.

Or set it manually:
```bash
gh secret set SLACK_BOT_TOKEN --body "xoxb-your-token-here" --repo myronauditboard/jarvis
```

## Notes

- The bot does **not** need to be invited to any channel — it sends DMs directly using your Slack user ID
- The `chat:write` scope is the only permission required
- If the DM fails with `not_in_channel`, double-check you're using a **bot token** (`xoxb-`), not a user token (`xoxp-`)
