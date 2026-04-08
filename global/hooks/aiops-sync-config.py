#!/usr/bin/env python3
import json, os, subprocess, sys
from datetime import datetime
from urllib.request import urlopen, Request

def load_env(path):
    if not os.path.isfile(path): return
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line: continue
            k, _, v = line.partition("=")
            os.environ.setdefault(k.strip(), v.strip())

for p in [os.path.expanduser("~/.claude/.env"), ".env", "../.env"]:
    load_env(p)

URL = os.environ.get("AIOPS_REMOTE_URL", "")
KEY = os.environ.get("AIOPS_API_KEY", "")
TID = os.environ.get("AIOPS_TENANT_ID", "")
if not all([URL, KEY, TID]): sys.exit(0)

try:
    root = subprocess.check_output(["git","rev-parse","--show-toplevel"], stderr=subprocess.DEVNULL).decode().strip()
except: root = os.getcwd()

GLOBAL_DIR = os.path.expanduser("~/.claude")

def rj(p):
    try:
        with open(p) as f: return json.load(f)
    except: return None

def rt(p, n=2000):
    try:
        with open(p) as f: return f.read(n)
    except: return ""

def scan_md(d):
    if not os.path.isdir(d): return []
    result = []
    for f in sorted(os.listdir(d)):
        fpath = os.path.join(d, f)
        if os.path.isfile(fpath) and f.endswith(".md"):
            result.append({"name": f, "content": rt(fpath, 1000)})
        elif os.path.isdir(fpath):
            agent_md = os.path.join(fpath, "AGENT.md")
            if os.path.isfile(agent_md):
                result.append({"name": f, "content": rt(agent_md, 1000)})
    return result

def scan_skills(d):
    if not os.path.isdir(d): return []
    result = []
    for f in sorted(os.listdir(d)):
        fpath = os.path.join(d, f)
        if os.path.isdir(fpath):
            skill_md = os.path.join(fpath, "SKILL.md")
            if os.path.isfile(skill_md):
                result.append({"name": f, "content": rt(skill_md, 1000)})
    return result

def scan_hook_scripts(d):
    if not os.path.isdir(d): return []
    return [{"name": f} for f in sorted(os.listdir(d))
            if os.path.isfile(os.path.join(d, f)) and (f.endswith(".sh") or f.endswith(".py"))]

def send(category, payload):
    body = json.dumps({"tenant_id": TID, "category": category, "payload": payload}, ensure_ascii=False).encode()
    try:
        req = Request(f"{URL}/api/ingest", data=body, headers={"Content-Type": "application/json", "X-API-Key": KEY}, method="POST")
        with urlopen(req, timeout=5) as r: print(f"[sync-config:{category}] {json.loads(r.read())}")
    except Exception as e: print(f"[sync-config:{category}] error: {e}", file=sys.stderr)

ts = datetime.now().astimezone().isoformat()

# ── 1. 프로젝트 설정 ──
cd = os.path.join(root, ".claude")
has = os.path.isdir(cd)

settings = rj(os.path.join(cd, "settings.local.json")) if has else None
hooks = []
if settings and "hooks" in settings:
    for ev, hl in settings["hooks"].items():
        if isinstance(hl, list):
            for h in hl:
                hooks.append({"event": ev, "matcher": h.get("matcher", ""), "command": h.get("command", "")[:120]})

mcp = rj(os.path.join(root, ".mcp.json"))
md = rt(os.path.join(root, "CLAUDE.md"))
rules = scan_md(os.path.join(cd, "rules")) if has else []
agents = scan_md(os.path.join(cd, "agents")) if has else []

send("claude-config-project", {
    "ts": ts, "scope": "project",
    "repoName": os.path.basename(root), "repoPath": root, "hasClaude": has,
    "settings": {"exists": settings is not None, "permissions": (settings or {}).get("permissions", {}), "plugins": (settings or {}).get("enabledPlugins", []), "raw": settings},
    "claudeMd": {"exists": bool(md), "content": md, "info": {}},
    "rules": rules, "agents": agents, "skills": [], "hooks": hooks,
    "mcp": {"exists": mcp is not None, "servers": list(mcp.get("mcpServers", {}).keys()) if mcp else [], "raw": mcp},
    "summary": {"totalItems": (1 if settings else 0) + (1 if md else 0) + len(rules) + len(agents) + (1 if mcp else 0)},
})

# ── 2. 글로벌 설정 ──
g_settings = rj(os.path.join(GLOBAL_DIR, "settings.json"))
g_hooks = []
if g_settings and "hooks" in g_settings:
    for ev, hl in g_settings["hooks"].items():
        if isinstance(hl, list):
            for h in hl:
                for hk in h.get("hooks", []):
                    g_hooks.append({"event": ev, "matcher": h.get("matcher", ""), "command": hk.get("command", "")[:120]})

g_md = rt(os.path.join(GLOBAL_DIR, "CLAUDE.md"))
g_rules = scan_md(os.path.join(GLOBAL_DIR, "rules"))
g_agents = scan_md(os.path.join(GLOBAL_DIR, "agents"))
g_skills = scan_skills(os.path.join(GLOBAL_DIR, "skills"))
g_hook_scripts = scan_hook_scripts(os.path.join(GLOBAL_DIR, "hooks"))

send("claude-config-global", {
    "ts": ts, "scope": "global",
    "sourcePath": GLOBAL_DIR,
    "settings": {"exists": g_settings is not None, "permissions": (g_settings or {}).get("permissions", {}), "plugins": (g_settings or {}).get("enabledPlugins", []), "raw": g_settings},
    "claudeMd": {"exists": bool(g_md), "content": g_md, "info": {}},
    "rules": g_rules, "agents": g_agents, "skills": g_skills, "hooks": g_hooks,
    "hookScripts": g_hook_scripts,
    "summary": {"totalItems": (1 if g_settings else 0) + (1 if g_md else 0) + len(g_rules) + len(g_agents) + len(g_skills) + len(g_hook_scripts)},
})
