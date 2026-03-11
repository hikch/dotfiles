# Tailscale Monitor

Automated health monitoring for Tailscale connections with Discord notifications.

## Overview

This monitoring system helps prevent remote access loss by:
- Monitoring Tailscale login status every 15 minutes
- Detecting authentication key expiration (30-day warning)
- Checking connection health
- Sending Discord notifications for issues
- Providing weekly status reports (Mondays 8-10 AM)

## Initial Setup

### 1. Enable Tailscale Key Expiry Disable

**Critical:** Prevent automatic logouts by disabling key expiration:

1. Visit https://login.tailscale.com/admin/machines
2. Find your machine (`imac-2020`)
3. Click on the machine name
4. Enable **"Disable key expiry"**

This ensures your Tailscale connection remains active indefinitely.

### 2. Create Discord Webhook

1. Open your Discord server (or create a personal server)
2. Create a dedicated channel for notifications (e.g., `#tailscale-alerts`)
3. Go to Channel Settings → Integrations → Webhooks
4. Click **"New Webhook"**
5. Copy the Webhook URL

### 3. Configure Webhook URL

```bash
# Navigate to dotfiles directory
cd ~/dotfiles

# Copy the template
cp .config/tailscale-monitor/webhook.env.example .config/tailscale-monitor/webhook.env

# Edit and add your webhook URL
vim .config/tailscale-monitor/webhook.env
# Replace YOUR_WEBHOOK_ID and YOUR_WEBHOOK_TOKEN with your actual webhook URL

# Protect the file
chmod 600 .config/tailscale-monitor/webhook.env
```

### 4. Deploy Configuration

```bash
# Deploy dotfiles (creates symlinks)
make deploy

# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/local.tailscale-monitor.plist
```

### 5. Test the Setup

```bash
# Run manual test
~/dotfiles/bin/tailscale-healthcheck

# Check if Discord notification was received
# You should see a status report in your Discord channel
```

## Monitoring Features

### Automatic Checks (Every 15 Minutes)

1. **Logout Detection**
   - Alerts when Tailscale is logged out
   - Provides recovery instructions
   - Critical priority (red alert)

2. **Connection Status**
   - Monitors online/offline state
   - Warns about network issues
   - Medium priority (yellow warning)

3. **Auth Key Expiration**
   - Warns 30 days before expiration
   - Includes instructions to disable expiry
   - Medium priority (yellow warning)

4. **Weekly Reports**
   - Sent every Monday between 8-10 AM
   - Summary of current status
   - Info priority (blue/green)

### Notification Examples

**Logout Alert:**
```
🚨 Tailscale Logged Out
Tailscale has been logged out on imac-2020!

You will not be able to connect remotely until you log back in.

To fix:
1. Access the machine locally
2. Run: `tailscale up --accept-routes --ssh --accept-dns`
```

**Expiration Warning:**
```
⏰ Tailscale Auth Key Expiring Soon
The authentication key for imac-2020 will expire in 25 days.

To prevent disconnection:
1. Go to https://login.tailscale.com/admin/machines
2. Find imac-2020
3. Enable 'Disable key expiry'
```

## File Structure

```
dotfiles/
├── bin/
│   └── tailscale-healthcheck          # Main monitoring script
├── .config/
│   └── tailscale-monitor/
│       ├── README.md                  # This file
│       ├── webhook.env.example        # Template configuration
│       └── webhook.env                # Your webhook URL (git-ignored)
└── Library/
    └── LaunchAgents/
        └── local.tailscale-monitor.plist  # Auto-start configuration
```

State files are stored in:
```
~/.local/state/tailscale-monitor/
├── last_state.json          # Previous Tailscale status
├── last_weekly_report       # Last report date
├── stdout.log               # Script output
└── stderr.log               # Error messages
```

## Troubleshooting

### No Discord Notifications

1. Check webhook URL configuration:
   ```bash
   cat ~/.config/tailscale-monitor/webhook.env
   ```

2. Test webhook manually:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     -d '{"content": "Test message"}' \
     "YOUR_WEBHOOK_URL"
   ```

3. Check script logs:
   ```bash
   cat ~/.local/state/tailscale-monitor/stderr.log
   ```

### LaunchAgent Not Running

1. Check if loaded:
   ```bash
   launchctl list | grep tailscale-monitor
   ```

2. Reload the agent:
   ```bash
   launchctl unload ~/Library/LaunchAgents/local.tailscale-monitor.plist
   launchctl load ~/Library/LaunchAgents/local.tailscale-monitor.plist
   ```

3. Check LaunchAgent logs:
   ```bash
   cat ~/.local/state/tailscale-monitor/stdout.log
   ```

### Manual Testing

Run the health check script manually to debug:
```bash
# Run with verbose output
sh -x ~/dotfiles/bin/tailscale-healthcheck

# Check Tailscale status directly
tailscale status --json | jq
```

## Customization

### Change Check Interval

Edit `Library/LaunchAgents/local.tailscale-monitor.plist`:
```xml
<key>StartInterval</key>
<integer>900</integer>  <!-- Change 900 (15 min) to desired seconds -->
```

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/local.tailscale-monitor.plist
launchctl load ~/Library/LaunchAgents/local.tailscale-monitor.plist
```

### Change Warning Threshold

Edit `bin/tailscale-healthcheck`:
```bash
WARN_DAYS=30  # Change to desired number of days
```

### Change Weekly Report Time

Edit the `is_weekly_report_due()` function in `bin/tailscale-healthcheck`:
```bash
# Currently: Monday (1), 8:00-10:00
day_of_week=$(date +%u)  # 1=Monday, 7=Sunday
hour=$(date +%H)         # 0-23
```

## Maintenance

### View Logs

```bash
# Real-time monitoring
tail -f ~/.local/state/tailscale-monitor/stdout.log

# View errors
cat ~/.local/state/tailscale-monitor/stderr.log
```

### Update Webhook URL

```bash
# Edit configuration
vim ~/.config/tailscale-monitor/webhook.env

# No need to reload - changes take effect on next run
```

### Disable Monitoring

```bash
# Unload LaunchAgent
launchctl unload ~/Library/LaunchAgents/local.tailscale-monitor.plist
```

### Re-enable Monitoring

```bash
# Load LaunchAgent
launchctl load ~/Library/LaunchAgents/local.tailscale-monitor.plist
```

## Security Notes

- `webhook.env` is git-ignored to prevent leaking webhook URLs
- File permissions are set to `600` (owner read/write only)
- Webhook URLs can only send messages to your Discord channel
- Even if leaked, webhook URLs cannot be used to access your Tailscale network
- State files contain no sensitive information

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review script logs in `~/.local/state/tailscale-monitor/`
3. Test Tailscale connection: `tailscale status`
4. Verify Discord webhook: Send test message via curl
