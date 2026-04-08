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

cd = os.path.join(root, ".claude")
has = os.path.isdir(cd)

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
    return [{"name":f,"content":rt(os.path.join(d,f),1000)} for f in sorted(os.listdir(d)) if f.endswith(".md") and os.path.isfile(os.path.join(d,f))]

settings = rj(os.path.join(cd,"settings.local.json")) if has else None
hooks = []
if settings and "hooks" in settings:
    for ev, hl in settings["hooks"].items():
        if isinstance(hl, list):
            for h in hl:
                hooks.append({"event":ev,"matcher":h.get("matcher",""),"command":h.get("command","")[:120]})

mcp = rj(os.path.join(root,".mcp.json"))
md = rt(os.path.join(root,"CLAUDE.md"))
rules = scan_md(os.path.join(cd,"rules")) if has else []
agents = scan_md(os.path.join(cd,"agents")) if has else []

payload = {
    "ts": datetime.now().astimezone().isoformat(),
    "scope": "project",
    "repoName": os.path.basename(root),
    "repoPath": root,
    "hasClaude": has,
    "settings": {"exists": settings is not None, "permissions": (settings or {}).get("permissions",{}), "plugins": (settings or {}).get("enabledPlugins",[]), "raw": settings},
    "claudeMd": {"exists": bool(md), "content": md, "info": {}},
    "rules": rules,
    "agents": agents,
    "skills": [],
    "hooks": hooks,
    "mcp": {"exists": mcp is not None, "servers": list(mcp.get("mcpServers",{}).keys()) if mcp else [], "raw": mcp},
    "summary": {"totalItems": (1 if settings else 0) + (1 if md else 0) + len(rules) + len(agents) + (1 if mcp else 0)},
}

body = json.dumps({"tenant_id":TID,"category":"claude-config-project","payload":payload}, ensure_ascii=False).encode()
try:
    req = Request(f"{URL}/api/ingest", data=body, headers={"Content-Type":"application/json","X-API-Key":KEY}, method="POST")
    with urlopen(req, timeout=5) as r: print(f"[sync-config] {json.loads(r.read())}")
except Exception as e: print(f"[sync-config] error: {e}", file=sys.stderr)
