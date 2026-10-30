# CloudLab

A lightweight browser-accessible Linux XFCE4 desktop, now with an experimental Project Lab for trying public GitHub projects.

## Desktop architecture

Ubuntu GitHub Actions runner
-> XFCE4
-> Selkies WebRTC
-> H.264 software-encoded desktop stream
-> Cloudflare Calls TURN when relay is required
-> Browser

Cloudflare Quick Tunnel provides HTTPS/WebSocket signaling and the web interface. Desktop media uses WebRTC, with TURN relay when needed.

## Project Lab

Project Lab is a first experimental add-on, launched from the desktop shortcut.

- Add a public GitHub repository URL and inspect its metadata.
- Save project definitions to a Hugging Face Dataset so they can be reloaded in later sessions.
- Clone a selected project into the temporary runner.
- Detect Python dependency metadata and ask before installing it into a project-specific virtual environment.
- Offer a Run action for a simple `main.py` or `app.py` entry point after confirmation.

Project Lab saves project definitions, not installed programs or cloned files. GitHub-hosted runners are temporary, so selected repositories are cloned again in each new session. This first version does not automatically install arbitrary system packages, Docker services, Node projects, or Windows apps.

### Configure Hugging Face persistence

Add these GitHub Actions repository secrets:

- `HF_TOKEN`: Hugging Face write access token.
- `HF_DATASET_REPO_ID`: dataset ID, e.g. `YOUR_USERNAME/cloudlab-projects`.

The app creates a private Dataset repository if needed and if the token has permission. Without these secrets, Project Lab runs in local-only mode and its library does not persist between sessions.

Review any repository before installing dependencies or running its code. Third-party install/build scripts can execute arbitrary code.

More details: [Project Lab README](project-lab/README.md).

## Cloudflare setup

The desktop workflow also expects:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

The Cloudflare API token needs Calls Write permission so the workflow can create a temporary TURN key for the session. The workflow removes that temporary key during cleanup. Keep both Cloudflare values in GitHub Actions Secrets; never commit them to repository files.

## Start a desktop session

Open **Actions → CloudLab Desktop → Run workflow** and choose a session duration of 1h, 3h, or 6h. The workflow prints the temporary desktop URL and credentials in the run summary.

The CloudLab Project Lab shortcut appears inside the XFCE4 desktop. The existing desktop transport remains Selkies WebRTC with WebSocket fallback available from the Selkies menu.

## Experimental status

This branch adds Project Lab for testing. It should be validated in a workflow run before merging into the stable branch.
