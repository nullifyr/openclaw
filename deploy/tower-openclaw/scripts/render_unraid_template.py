#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deploy" / "unraid" / "openclaw-tower.xml"

APP = {
    "name": "openclaw-tower",
    "repository": "openclaw-nullifyr:latest",
    "overview": "Custom OpenClaw Tower runtime built from the local GitHub fork and a tiny Tower-specific overlay.",
    "webui": "http://[IP]:[PORT:18789]/",
    "icon": "https://raw.githubusercontent.com/openclaw/openclaw/main/docs/static/img/logo.png",
    "network": "bridge",
    "shell": "bash",
    "privileged": "false",
    "support": "https://github.com/nullifyr/openclaw",
    "project": "https://github.com/nullifyr/openclaw",
    "category": "Tools:Utilities",
    "extra_params": "--restart=unless-stopped --hostname=openclaw-tower --log-opt max-size=50m --log-opt max-file=1",
}

CONFIGS = [
    {
        "name": "Web UI Port",
        "target": "18789",
        "default": "18790",
        "mode": "tcp",
        "description": "Host port that maps to the OpenClaw gateway inside the container.",
        "type": "Port",
        "display": "always",
        "required": "true",
        "mask": "false",
    },
    {
        "name": "Config Path",
        "target": "/home/node/.openclaw",
        "default": "/mnt/cache/appdata/openclaw-tower/config",
        "mode": "rw",
        "description": "Persistent OpenClaw config/state path on cache.",
        "type": "Path",
        "display": "always",
        "required": "true",
        "mask": "false",
    },
    {
        "name": "Workspace Path",
        "target": "/home/node/.openclaw/workspace",
        "default": "/mnt/cache/appdata/openclaw-tower/workspace",
        "mode": "rw",
        "description": "Persistent workspace, memory, skills, and project files.",
        "type": "Path",
        "display": "always",
        "required": "true",
        "mask": "false",
    },
    {
        "name": "Docker Socket",
        "target": "/var/run/docker.sock",
        "default": "/var/run/docker.sock",
        "mode": "rw",
        "description": "Optional Docker socket passthrough for local Docker-aware tooling.",
        "type": "Path",
        "display": "always",
        "required": "false",
        "mask": "false",
    },
    {
        "name": "BudTrak Data Path",
        "target": "/mnt/cache/data/dispensary-tracker",
        "default": "/mnt/cache/data/dispensary-tracker",
        "mode": "rw",
        "description": "BudTrak data share mounted for Tower-local review and repair tasks.",
        "type": "Path",
        "display": "always",
        "required": "false",
        "mask": "false",
    },
    {
        "name": "BudTrak Build Path",
        "target": "/mnt/cache/tmp/budtrak-build",
        "default": "/mnt/cache/tmp/budtrak-build",
        "mode": "rw",
        "description": "Temporary BudTrak build workspace mounted into OpenClaw for local repair flows.",
        "type": "Path",
        "display": "advanced",
        "required": "false",
        "mask": "false",
    },
    {
        "name": "Timezone",
        "target": "TZ",
        "default": "America/Phoenix",
        "mode": "",
        "description": "Container timezone.",
        "type": "Variable",
        "display": "always",
        "required": "true",
        "mask": "false",
    },
    {
        "name": "Gateway Password",
        "target": "OPENCLAW_GATEWAY_PASSWORD",
        "default": "",
        "mode": "",
        "description": "Gateway password for the Tower OpenClaw runtime.",
        "type": "Variable",
        "display": "always",
        "required": "true",
        "mask": "true",
    },
    {
        "name": "Google API Key",
        "target": "GOOGLE_API_KEY",
        "default": "",
        "mode": "",
        "description": "Used by Gemini-backed memory/embedding paths when configured.",
        "type": "Variable",
        "display": "advanced",
        "required": "false",
        "mask": "true",
    },
    {
        "name": "Anthropic API Key",
        "target": "ANTHROPIC_API_KEY",
        "default": "",
        "mode": "",
        "description": "Optional Anthropic runtime fallback key.",
        "type": "Variable",
        "display": "advanced",
        "required": "false",
        "mask": "true",
    },
    {
        "name": "OpenAI API Key",
        "target": "OPENAI_API_KEY",
        "default": "",
        "mode": "",
        "description": "Optional OpenAI runtime fallback key.",
        "type": "Variable",
        "display": "advanced",
        "required": "false",
        "mask": "true",
    },
    {
        "name": "Container Hint",
        "target": "OPENCLAW_CONTAINER_HINT",
        "default": "openclaw-tower",
        "mode": "",
        "description": "Improves container-targeted CLI guidance inside the runtime.",
        "type": "Variable",
        "display": "advanced",
        "required": "false",
        "mask": "false",
    },
]

container = ET.Element("Container", version="2")
for tag, value in [
    ("Name", APP["name"]),
    ("Repository", APP["repository"]),
    ("Network", APP["network"]),
    ("MyIP", ""),
    ("Shell", APP["shell"]),
    ("Privileged", APP["privileged"]),
    ("Support", APP["support"]),
    ("Project", APP["project"]),
    ("Overview", APP["overview"]),
    ("Category", APP["category"]),
    ("WebUI", APP["webui"]),
    ("Icon", APP["icon"]),
    ("ExtraParams", APP["extra_params"]),
]:
    ET.SubElement(container, tag).text = value

for cfg in CONFIGS:
    el = ET.SubElement(
        container,
        "Config",
        Name=cfg["name"],
        Target=cfg["target"],
        Default=cfg["default"],
        Mode=cfg["mode"],
        Description=cfg["description"],
        Type=cfg["type"],
        Display=cfg["display"],
        Required=cfg["required"],
        Mask=cfg["mask"],
    )
    el.text = cfg["default"]

OUT.parent.mkdir(parents=True, exist_ok=True)
ET.indent(ET.ElementTree(container), space="  ")
ET.ElementTree(container).write(OUT, encoding="utf-8", xml_declaration=True)
print(OUT)
