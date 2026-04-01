# Email Notifications Setup

Jarvis uses email as a fallback when Slack is unavailable or not configured. It fires automatically whenever the Slack step fails or is skipped.

## How It Works

The GitHub Actions workflow uses [dawidd6/action-send-mail](https://github.com/dawidd6/action-send-mail) to send email via SMTP. Any SMTP provider works — Gmail is the most common.

## Gmail Setup (Recommended)

### 1. Enable 2-Factor Authentication

Gmail app passwords require 2FA to be enabled on your Google account.

### 2. Create an App Password

1. Go to: https://myaccount.google.com/apppasswords
2. Select **Mail** as the app
3. Click **Generate**
4. Copy the 16-character password (no spaces)

### 3. Add GitHub Secrets

Add these 4 secrets to the Jarvis repo (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `SMTP_SERVER` | `smtp.gmail.com` |
| `SMTP_USERNAME` | Your Gmail address (e.g. `you@gmail.com`) |
| `SMTP_PASSWORD` | The 16-character app password from step 2 |
| `NOTIFY_EMAIL` | Where to deliver notifications (can be the same Gmail or any address) |

Or set them via CLI:
```bash
gh secret set SMTP_SERVER   --body "smtp.gmail.com"        --repo myronauditboard/jarvis
gh secret set SMTP_USERNAME --body "you@gmail.com"         --repo myronauditboard/jarvis
gh secret set SMTP_PASSWORD --body "your-app-password"     --repo myronauditboard/jarvis
gh secret set NOTIFY_EMAIL  --body "you@yourcompany.com"   --repo myronauditboard/jarvis
```

## Other SMTP Providers

Any provider with SMTP access works. Common alternatives:

| Provider | `SMTP_SERVER` | Port |
|----------|--------------|------|
| Gmail | `smtp.gmail.com` | 587 |
| Outlook/Hotmail | `smtp-mail.outlook.com` | 587 |
| iCloud | `smtp.mail.me.com` | 587 |
| Fastmail | `smtp.fastmail.com` | 587 |

## Notification Priority

Jarvis always tries Slack first. Email only fires when:
- `SLACK_BOT_TOKEN` is not set, or
- The Slack API call fails (invalid token, app not approved, etc.)

Once your Slack app is approved, email stops firing automatically — no config change needed.
