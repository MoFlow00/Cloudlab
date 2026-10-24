# CloudLab Project Lab

Experimental Project Lab add-on for the current XFCE4/Selkies desktop.

## First version

- Add public GitHub repositories by URL and fetch metadata.
- Save project definitions to a Hugging Face Dataset repository.
- Reload the saved library in future GitHub Actions sessions.
- Clone a selected repository into the temporary session.
- Record install commands typed in a dedicated CloudLab terminal, review and save them as a per-project recipe, then replay the recipe in later sessions after explicit confirmation.
- Detect Python dependency metadata and ask before installing into a project-specific virtual environment.
- Offer a Run action for a simple main.py or app.py entry point, with confirmation.
- Never run install scripts simply because a URL was saved.

## One-time Hugging Face setup

1. Create a private Dataset repository on Hugging Face, e.g. YOUR_USERNAME/cloudlab-projects. The app can also create it if it does not exist and the token has write permission.
2. Create a Hugging Face write access token.
3. In GitHub repository Settings > Secrets and variables > Actions > Secrets, add:
   - HF_TOKEN: the Hugging Face write token.
   - HF_DATASET_REPO_ID: the dataset ID, e.g. YOUR_USERNAME/cloudlab-projects.
4. Start a new CloudLab session.

Without these secrets the app opens in local-only mode; the library will not persist between sessions.

## Limitations and safety

- GitHub Actions runners are temporary. This saves project definitions, not installed applications or cloned files. Projects are cloned again in a new session.
- Install recipes record commands typed in the dedicated recorder terminal only; they do not capture browser clicks or commands run in other terminals. Review recipes before saving or replaying, never record passwords/API tokens, and expect to edit commands that use session-specific paths or interactive prompts.
- The generic installer still does not automatically understand every project type. A recorded recipe can replay apt, pip, npm, .deb, and other shell commands, but those commands may require adaptation and can fail in a fresh temporary session.
- Installing third-party dependencies or running code can execute untrusted code. Review projects and approve each install/run action.
- Never store Hugging Face tokens in repository files. Use GitHub Actions Secrets.

## Test checklist

- [ ] Desktop opens as before.
- [ ] Project Lab desktop shortcut launches.
- [ ] Add a public GitHub URL.
- [ ] Configure Hugging Face secrets and save the library.
- [ ] Start a new session and confirm saved projects appear.
- [ ] Clone a small trusted Python repository and test dependency installation.
