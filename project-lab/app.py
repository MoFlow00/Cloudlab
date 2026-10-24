#!/usr/bin/env python3
"""CloudLab Project Lab: save and prepare public GitHub projects for temporary Linux sessions."""
import json, re, subprocess, threading, urllib.parse, urllib.request
from pathlib import Path
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog

HOME = Path.home()
CFG = HOME / ".config/cloudlab"
SECRETS = CFG / "secrets.json"
CACHE = CFG / "projects-cache.json"
RECORDING = CFG / "install-recording.history"
PROJECTS = HOME / "Projects/CloudLab"
CFG.mkdir(parents=True, exist_ok=True)
PROJECTS.mkdir(parents=True, exist_ok=True)

def read_json(path, fallback):
    try: return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError): return fallback

def normalize_url(raw):
    p = urllib.parse.urlparse(raw.strip())
    bits = [x for x in p.path.split("/") if x]
    if p.scheme != "https" or p.netloc.lower() != "github.com" or len(bits) < 2:
        raise ValueError("Enter a public repository URL like https://github.com/owner/repository")
    owner, repo = bits[:2]
    repo = repo.removesuffix(".git")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", owner) or not re.fullmatch(r"[A-Za-z0-9_.-]+", repo):
        raise ValueError("Invalid GitHub repository URL.")
    return f"https://github.com/{owner}/{repo}"

def metadata(url):
    owner, repo = urllib.parse.urlparse(url).path.strip("/").split("/", 1)
    req = urllib.request.Request(f"https://api.github.com/repos/{owner}/{repo}",
        headers={"Accept":"application/vnd.github+json","User-Agent":"CloudLab-Project-Lab"})
    with urllib.request.urlopen(req, timeout=15) as r: d = json.load(r)
    if d.get("private"): raise ValueError("This first version supports public repositories only.")
    return {"url":d["html_url"].rstrip("/"),"name":d.get("full_name",f"{owner}/{repo}"),
            "description":d.get("description") or "No description provided.",
            "default_branch":d.get("default_branch") or "main"}

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("CloudLab Project Lab")
        self.geometry("850x570"); self.minsize(700,450)
        self.secrets = read_json(SECRETS,{})
        self.projects = read_json(CACHE,[])
        if not isinstance(self.projects,list): self.projects=[]
        self.make_ui(); self.refresh()
        self.after(250,self.startup_sync)

    def make_ui(self):
        root=ttk.Frame(self,padding=14); root.pack(fill="both",expand=True)
        ttk.Label(root,text="CloudLab Project Lab",font=("Sans",18,"bold")).pack(anchor="w")
        ttk.Label(root,text="Save GitHub projects once, then find and prepare them in future sessions.").pack(anchor="w",pady=(3,12))
        row=ttk.Frame(root); row.pack(fill="x",pady=(0,10))
        self.url=tk.StringVar()
        ttk.Entry(row,textvariable=self.url).pack(side="left",fill="x",expand=True,padx=(0,8))
        ttk.Button(row,text="Add Project",command=self.add).pack(side="left")
        panes=ttk.Panedwindow(root,orient="horizontal"); panes.pack(fill="both",expand=True)
        left=ttk.Frame(panes,padding=(0,0,10,0)); right=ttk.Frame(panes)
        panes.add(left,weight=1); panes.add(right,weight=2)
        ttk.Label(left,text="My Projects",font=("Sans",11,"bold")).pack(anchor="w")
        self.list=tk.Listbox(left,exportselection=False); self.list.pack(fill="both",expand=True,pady=5)
        self.list.bind("<<ListboxSelect>>",lambda _e:self.show_details())
        ttk.Button(left,text="Install / Prepare",command=self.install).pack(fill="x",pady=2)
        ttk.Button(left,text="Record install",command=self.record_install).pack(fill="x",pady=2)
        ttk.Button(left,text="Save recorded recipe",command=self.save_recipe).pack(fill="x",pady=2)
        ttk.Button(left,text="Install from recipe",command=self.install_recipe).pack(fill="x",pady=2)
        ttk.Button(left,text="Run",command=self.run_project).pack(fill="x",pady=2)
        ttk.Button(left,text="Remove from library",command=self.remove).pack(fill="x",pady=2)
        ttk.Label(right,text="Details",font=("Sans",11,"bold")).pack(anchor="w")
        self.details=tk.Text(right,height=12,wrap="word",state="disabled"); self.details.pack(fill="both",expand=True,pady=5)
        self.log=tk.Text(right,height=7,wrap="word",state="disabled"); self.log.pack(fill="both",expand=True)
        foot=ttk.Frame(root); foot.pack(fill="x",pady=(10,0))
        self.status=tk.StringVar(value="Ready.")
        ttk.Label(foot,textvariable=self.status,wraplength=470).pack(side="left",fill="x",expand=True)
        ttk.Button(foot,text="Save to My Projects",command=self.save).pack(side="right",padx=(8,0))
        ttk.Button(foot,text="Refresh",command=self.sync).pack(side="right")

    def box(self,w,text):
        w.configure(state="normal"); w.delete("1.0","end"); w.insert("1.0",text); w.configure(state="disabled")
    def logline(self,text):
        self.log.configure(state="normal"); self.log.insert("end",str(text)+"\n"); self.log.see("end"); self.log.configure(state="disabled")
    def selected(self):
        s=self.list.curselection()
        return self.projects[s[0]] if s and s[0]<len(self.projects) else None
    def path(self,item):
        owner,repo=urllib.parse.urlparse(item["url"]).path.strip("/").split("/",1)
        return PROJECTS/f"{owner}__{repo}"
    def refresh(self,selected_url=None):
        self.list.delete(0,"end")
        for p in self.projects: self.list.insert("end",p.get("name",p.get("url","Project")))
        if self.projects:
            idx=next((i for i,p in enumerate(self.projects) if p.get("url")==selected_url),0)
            self.list.selection_set(idx); self.list.activate(idx); self.show_details()
        else: self.box(self.details,"No saved projects yet.\n\nPaste a public GitHub repository URL and choose Add Project.")
    def show_details(self):
        p=self.selected()
        if not p:return
        present=self.path(p).exists()
        self.box(self.details,f"{p.get('name')}\n\n{p.get('description','')}\n\nURL: {p.get('url')}\nDefault branch: {p.get('default_branch','main')}\nLocal checkout this session: {'yes' if present else 'no'}\n\nInstall / Prepare clones the repository. Record install opens a dedicated terminal that records commands you type there; review them before saving. Install from recipe replays the saved commands with confirmation.")
    def cache(self):
        CACHE.write_text(json.dumps(self.projects,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    def add(self):
        try:
            url=normalize_url(self.url.get())
            if any(p.get("url","").lower()==url.lower() for p in self.projects):
                messagebox.showinfo("Already saved","This repository is already in My Projects."); return
            self.status.set("Checking GitHub repository…")
            p=metadata(url); self.projects.append(p); self.cache(); self.refresh(url)
            self.url.set(""); self.status.set("Added project. Click Save to My Projects to sync it across sessions.")
        except Exception as e: self.status.set("Could not add project."); messagebox.showerror("Add Project",str(e))
    def hub(self):
        token=(self.secrets.get("HF_TOKEN") or "").strip()
        repo=(self.secrets.get("HF_DATASET_REPO_ID") or "").strip()
        if not token or not repo:
            raise RuntimeError("Hugging Face is not configured. Add GitHub Actions secrets HF_TOKEN and HF_DATASET_REPO_ID, then start a new session. Dataset ID example: username/cloudlab-projects.")
        from huggingface_hub import HfApi
        return HfApi(token=token),token,repo
    def read_remote(self):
        api,token,repo=self.hub()
        api.create_repo(repo_id=repo,repo_type="dataset",private=True,exist_ok=True)
        from huggingface_hub import hf_hub_download
        try:
            f=hf_hub_download(repo_id=repo,repo_type="dataset",filename="projects.json",token=token,force_download=True)
            data=json.loads(Path(f).read_text(encoding="utf-8"))
            if not isinstance(data,list): raise ValueError("projects.json must contain a JSON array.")
            return data
        except Exception as e:
            msg=str(e).lower()
            if "entry not found" in msg or "404" in msg or "does not exist" in msg:return []
            raise
    def write_remote(self):
        api,token,repo=self.hub()
        api.create_repo(repo_id=repo,repo_type="dataset",private=True,exist_ok=True)
        api.upload_file(path_or_fileobj=(json.dumps(self.projects,indent=2,ensure_ascii=False)+"\n").encode(),
            path_in_repo="projects.json",repo_id=repo,repo_type="dataset",token=token,
            commit_message="Update CloudLab project library")
        return f"Saved {len(self.projects)} project(s) to Hugging Face dataset {repo}."
    def worker(self,fn):
        self.status.set("Working…")
        def run():
            try: result=fn()
            except Exception as e: result=f"Error: {e}"
            self.after(0,lambda:self.status.set(result))
            self.after(0,lambda:self.logline(result))
        threading.Thread(target=run,daemon=True).start()
    def startup_sync(self):
        if self.secrets.get("HF_TOKEN") and self.secrets.get("HF_DATASET_REPO_ID"): self.sync()
        else:self.status.set("Local mode. Add Hugging Face secrets to keep the library between sessions.")
    def sync(self):
        def work():
            self.projects=self.read_remote(); self.cache(); self.after(0,self.refresh)
            return f"Loaded {len(self.projects)} project(s) from Hugging Face."
        self.worker(work)
    def save(self):
        self.cache(); self.worker(self.write_remote)
    def remove(self):
        p=self.selected()
        if not p:return
        if not messagebox.askyesno("Remove project",f"Remove {p.get('name')} from the library? Local files will not be deleted."):return
        self.projects=[x for x in self.projects if x.get("url")!=p.get("url")]
        self.cache(); self.refresh(); self.status.set("Removed locally. Click Save to My Projects to sync.")
    def install(self):
        p=self.selected()
        if not p:messagebox.showinfo("Choose project","Select a project first.");return
        dest=self.path(p)
        if dest.exists():messagebox.showinfo("Already prepared",f"Already cloned this session:\n{dest}");return
        if not messagebox.askyesno("Clone repository",f"Clone this public repository?\n\n{p['url']}\n\nCloning alone does not run the project's code."):return
        def work():
            dest.parent.mkdir(parents=True,exist_ok=True)
            subprocess.run(["git","clone","--depth","1",p["url"],str(dest)],check=True,capture_output=True,text=True,timeout=300)
            req=dest/"requirements.txt"; pyproject=dest/"pyproject.toml"
            if req.exists() or pyproject.exists():
                answer=threading.Event(); choice={"yes":False}
                def ask():
                    choice["yes"]=messagebox.askyesno("Install dependencies?","Python dependency installation may execute third-party build/setup code. Continue only if you trust this repository.")
                    answer.set()
                self.after(0,ask); answer.wait()
                if choice["yes"]:
                    venv=dest/".venv"
                    subprocess.run(["python3","-m","venv",str(venv)],check=True,capture_output=True,text=True,timeout=120)
                    pip=str(venv/"bin"/"pip")
                    cmd=[pip,"install","-r",str(req)] if req.exists() else [pip,"install","-e",str(dest)]
                    out=subprocess.run(cmd,check=True,capture_output=True,text=True,timeout=900)
                    return f"Prepared {dest}\nDependencies installed.\n{out.stdout[-1200:]}"
            return f"Cloned successfully:\n{dest}\nNo dependencies were installed automatically."
        self.worker(work)
    def record_install(self):
        p=self.selected()
        if not p:
            messagebox.showinfo("Choose project","Select a project first."); return
        if not messagebox.askyesno("Record install", "A dedicated terminal will open. Run the installation steps for this selected project INSIDE that terminal.\n\nCommands may contain secrets or destructive actions. Do not type passwords or tokens. When finished, close the terminal and choose Save recorded recipe."):
            return
        RECORDING.parent.mkdir(parents=True,exist_ok=True)
        RECORDING.write_text("",encoding="utf-8")
        # Bash appends each completed interactive command to a plain-text log.
        # Only commands typed in this dedicated terminal are recorded.
        script = (
            "export HISTFILE=/dev/null; set -o history; "
            "PROMPT_COMMAND='history -a; history 1 | sed -E \\\"s/^ *[0-9]+ *//\\\" >> "
            + __import__("shlex").quote(str(RECORDING))
            + "'; "
            "echo 'CLOUDLAB INSTALL RECORDING ACTIVE'; "
            "echo 'Type the installation commands here. Do not enter passwords or API tokens.'; "
            "exec bash --noprofile --norc -i"
        )
        # PROMPT_COMMAND must be active in the interactive shell itself.
        script = "export HISTFILE=/dev/null; export PROMPT_COMMAND=" + __import__("shlex").quote("history 1 | sed -E 's/^ *[0-9]+ *//' >> " + str(RECORDING)) + "; echo 'CLOUDLAB INSTALL RECORDING ACTIVE'; echo 'Run install commands in this terminal. Do not type secrets.'; bash --noprofile --norc -i"
        try:
            subprocess.Popen(["xfce4-terminal","--title=CloudLab Install Recorder","--command","bash -lc "+__import__("shlex").quote(script)],start_new_session=True)
            self.status.set("Recording started. Run installation commands in the new terminal, close it when finished, then save the recipe.")
        except Exception as e: messagebox.showerror("Recorder failed",str(e))

    def save_recipe(self):
        p=self.selected()
        if not p:
            messagebox.showinfo("Choose project","Select a project first."); return
        if not RECORDING.exists():
            messagebox.showinfo("No recording","Choose Record install first and run commands in its terminal."); return
        lines=[]
        for line in RECORDING.read_text(encoding="utf-8",errors="replace").splitlines():
            line=line.strip()
            if not line or line.startswith("#") or line in {"exit","clear","history"}:
                continue
            if line not in lines: lines.append(line)
        if not lines:
            messagebox.showinfo("Empty recording","No commands were captured. Make sure you typed the commands in the recorder terminal."); return
        preview="\\n".join(f"{i+1}. {cmd}" for i,cmd in enumerate(lines))
        if not messagebox.askyesno("Review install recipe",f"Save {len(lines)} captured command(s) for {p.get('name')}?\\n\\n{preview[:3500]}\\n\\nReview carefully: commands can contain paths, destructive actions, or secrets."):
            return
        p["install_recipe"]=lines
        p["recipe_updated"]="manual-recording"
        self.cache()
        self.status.set(f"Saved {len(lines)} install command(s) locally. Click Save to My Projects to persist across sessions.")
        self.logline(f"Saved recipe for {p.get('name')}: {len(lines)} commands.")

    def install_recipe(self):
        p=self.selected()
        if not p:
            messagebox.showinfo("Choose project","Select a project first."); return
        recipe=p.get("install_recipe") or []
        if not recipe:
            messagebox.showinfo("No recipe","This project has no saved install recipe yet. Use Record install first."); return
        preview="\\n".join(f"{i+1}. {cmd}" for i,cmd in enumerate(recipe))
        if not messagebox.askyesno("Replay install recipe",f"Replay {len(recipe)} recorded command(s) for {p.get('name')}?\\n\\n{preview[:3500]}\\n\\nOnly continue if you trust and recognize every command. Some commands may need edits for a new session."):
            return
        # Commands are saved as data and only run after an explicit user confirmation.
        recipe_file=CFG / "replay-install-recipe.sh"
        recipe_file.write_text("#!/usr/bin/env bash\\nset -e\\n" + "\\n".join(recipe) + "\\n",encoding="utf-8")
        recipe_file.chmod(0o700)
        try:
            subprocess.Popen(["xfce4-terminal","--hold","--command","bash -lc "+__import__("shlex").quote("bash "+__import__("shlex").quote(str(recipe_file))+"; rc=$?; echo; echo 'Recipe finished with exit code' $rc; exec bash -i")],start_new_session=True)
            self.status.set("Install recipe launched in a terminal.")
        except Exception as e: messagebox.showerror("Recipe failed",str(e))

    def run_project(self):
        p=self.selected()
        if not p:messagebox.showinfo("Choose project","Select a project first.");return
        dest=self.path(p)
        if not dest.exists():messagebox.showinfo("Not prepared","Choose Install / Prepare first.");return
        entry=next((dest/n for n in ("main.py","app.py") if (dest/n).is_file()),None)
        if not entry:
            messagebox.showwarning("Manual start needed","No simple main.py or app.py entry point found. Review the project's README and start command first.");return
        if not messagebox.askyesno("Run project code?",f"Run {entry.name} from {p.get('name')}?\nOnly run code from repositories you trust."):return
        py=dest/".venv/bin/python"
        exe=str(py if py.exists() else Path("/usr/bin/python3"))
        cmd=f"cd {str(dest)} && exec {exe} {entry.name}"
        try:
            subprocess.Popen(["xfce4-terminal","--hold","--command",f"bash -lc {__import__('shlex').quote(cmd)}"],start_new_session=True)
            self.status.set(f"Started {entry.name} in a terminal.")
        except Exception as e:messagebox.showerror("Run failed",str(e))

if __name__=="__main__": App().mainloop()
