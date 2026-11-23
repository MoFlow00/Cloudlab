# IPTV runner setup

The GitHub Actions workflow runs at 06:00 and 18:00 UAE time.
Each run executes `node iptv.js` for up to 15 minutes, then stops the process and ends the runner job.

## Repository files

- `iptv.js`: paste your permitted script here.
- `iptv_settings.js`: reads credentials from GitHub Actions environment variables.
- `base.m3u`: add this file to the repository root if your script reads it locally.

## GitHub repository secrets

Add these under Settings > Secrets and variables > Actions:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`
- `IPTV_GITHUB_TOKEN`: token with the required access to the destination repository.
- `IPTV_GITHUB_REPO`: destination in `owner/repository` format, for example `MoFlow00/base`.

The workflow installs Node.js 22, Chromium, and `puppeteer-core`.
Set your script's Chromium executable path from `process.env.CHROME_PATH` (value: `/usr/bin/chromium`).

The workflow does not implement CAPTCHA or Cloudflare protection bypasses. Use only an authorized, permitted access flow.
