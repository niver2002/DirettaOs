#!/usr/bin/env python3
"""
Diretta appliance onboarding scaffold.

A minimal first-boot web service distinct from the runtime renderer config UI.
It persists onboarding fields into a dedicated onboarding env file and tracks a
simple appliance state marker under /etc/diretta-appliance/.
"""

import argparse
import json
import os
from html import escape
from http.server import HTTPServer, BaseHTTPRequestHandler
from string import Template
from urllib.parse import parse_qs

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_STATE_DIR = "/etc/diretta-appliance"
DEFAULT_STATE_FILE = "state"
DEFAULT_ONBOARDING_STATE = "onboarding-required"


def load_profile(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _escape_shell_value(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("`", "\\`")
        .replace("\n", "\\n")
    )


def _unescape_shell_value(value):
    return (
        value.replace("\\n", "\n")
        .replace("\\$", "$")
        .replace("\\`", "`")
        .replace('\\"', '"')
        .replace("\\\\", "\\")
    )


def load_shell_vars(path):
    settings = {}
    if not os.path.exists(path):
        return settings

    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
                value = value[1:-1]
            settings[key.strip()] = _unescape_shell_value(value)
    return settings


def save_shell_vars(path, settings):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = [
        "# Diretta appliance onboarding state\n",
    ]
    for key, value in settings.items():
        escaped = _escape_shell_value(value)
        lines.append(f'{key}="{escaped}"\n')

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)


def load_state(state_dir):
    path = os.path.join(state_dir, DEFAULT_STATE_FILE)
    if not os.path.exists(path):
        return DEFAULT_ONBOARDING_STATE
    with open(path, "r", encoding="utf-8") as f:
        value = f.read().strip()
    return value or DEFAULT_ONBOARDING_STATE


def save_state(state_dir, value):
    os.makedirs(state_dir, exist_ok=True)
    path = os.path.join(state_dir, DEFAULT_STATE_FILE)
    with open(path, "w", encoding="utf-8") as f:
        f.write(value + "\n")


def render_setting_input(setting, current_value):
    key = setting["key"]
    stype = setting.get("type", "text")
    value = escape(str(current_value)) if current_value is not None else ""

    if stype == "select":
        options_html = []
        for opt in setting.get("options", []):
            selected = " selected" if opt["value"] == current_value else ""
            options_html.append(
                f'<option value="{escape(opt["value"])}"{selected}>{escape(opt["label"])}</option>'
            )
        return f'<select name="{key}">' + "\n".join(options_html) + "</select>"

    if stype == "number":
        attrs = [
            'type="number"',
            f'name="{key}"',
            f'value="{value}"',
            f'placeholder="{escape(str(setting.get("default", "")))}"',
        ]
        if "min" in setting:
            attrs.append(f'min="{setting["min"]}"')
        if "max" in setting:
            attrs.append(f'max="{setting["max"]}"')
        return "<input " + " ".join(attrs) + ">"

    return (
        f'<input type="text" name="{key}" value="{value}" '
        f'placeholder="{escape(str(setting.get("default", "")))}">'
    )


def render_groups_html(profile, current_settings):
    html = []
    for group in profile.get("groups", []):
        collapsed = group.get("collapsed", False)
        body_class = " collapsed" if collapsed else ""
        toggle_class = " open" if not collapsed else ""
        settings_html = []
        for setting in group.get("settings", []):
            key = setting["key"]
            current = current_settings.get(key, setting.get("default", ""))
            desc = setting.get("description", "")
            desc_html = f'<div class="description">{escape(desc)}</div>' if desc else ""
            input_html = render_setting_input(setting, current)
            settings_html.append(
                "\n".join(
                    [
                        '<div class="setting">',
                        f'  <label>{escape(setting["label"])}</label>',
                        f"  {desc_html}",
                        f"  {input_html}",
                        "</div>",
                    ]
                )
            )
        html.append(
            "\n".join(
                [
                    '<div class="group">',
                    '  <div class="group-header">',
                    f'    <h2>{escape(group["name"])}</h2>',
                    f'    <span class="toggle{toggle_class}">&#9654;</span>',
                    "  </div>",
                    f'  <div class="group-body{body_class}">',
                    "\n".join(settings_html),
                    "  </div>",
                    "</div>",
                ]
            )
        )
    return "\n".join(html)


def render_page(profile, current_settings, state_value, flash=None):
    template_path = os.path.join(BASE_DIR, "templates", "onboarding.html")
    with open(template_path, "r", encoding="utf-8") as f:
        template = Template(f.read())

    flash_html = ""
    if flash:
        css_class = "success" if flash[0] else "error"
        flash_html = f'<div class="flash {css_class}">{escape(flash[1])}</div>'

    return template.safe_substitute(
        product_name=escape(profile.get("product_name", "Diretta Appliance")),
        flash_html=flash_html,
        groups_html=render_groups_html(profile, current_settings),
        state_value=escape(state_value),
    )


class OnboardingHandler(BaseHTTPRequestHandler):
    profile = None
    state_dir = DEFAULT_STATE_DIR

    def log_message(self, fmt, *args):
        print(f"[onboarding] {args[0]}")

    def _send_html(self, html, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(html.encode("utf-8"))))
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))

    def _send_redirect(self, location):
        self.send_response(303)
        self.send_header("Location", location)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/static/"):
            self._serve_static()
            return

        if self.path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return

        flash = None
        if "?" in self.path:
            qs = parse_qs(self.path.split("?", 1)[1])
            if "ok" in qs:
                flash = (True, qs["ok"][0])
            elif "err" in qs:
                flash = (False, qs["err"][0])

        current = load_shell_vars(self.profile["config_path"])
        state_value = load_state(self.state_dir)
        html = render_page(self.profile, current, state_value, flash)
        self._send_html(html)

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        form = parse_qs(body, keep_blank_values=True)

        if self.path == "/save":
            self._handle_save(form)
        elif self.path == "/complete":
            save_state(self.state_dir, "operational")
            self._send_redirect("/?ok=Onboarding marked operational.")
        elif self.path == "/reset":
            save_state(self.state_dir, DEFAULT_ONBOARDING_STATE)
            self._send_redirect("/?ok=Onboarding state reset.")
        else:
            self._send_redirect("/")

    def _handle_save(self, form):
        settings = {}
        for group in self.profile.get("groups", []):
            for setting in group.get("settings", []):
                key = setting["key"]
                settings[key] = form[key][0] if key in form else ""

        try:
            save_shell_vars(self.profile["config_path"], settings)
            if load_state(self.state_dir) == DEFAULT_ONBOARDING_STATE:
                save_state(self.state_dir, "network-setup")
        except Exception as exc:
            self._send_redirect(f"/?err=Save failed: {exc}")
            return

        self._send_redirect("/?ok=Onboarding settings saved.")

    def _serve_static(self):
        rel_path = self.path[len("/static/") :]
        if ".." in rel_path or rel_path.startswith("/"):
            self.send_response(403)
            self.end_headers()
            return

        file_path = os.path.join(BASE_DIR, "static", rel_path)
        if not os.path.isfile(file_path):
            self.send_response(404)
            self.end_headers()
            return

        content_types = {
            ".css": "text/css",
            ".js": "application/javascript",
            ".png": "image/png",
            ".ico": "image/x-icon",
        }
        ext = os.path.splitext(file_path)[1]
        content_type = content_types.get(ext, "application/octet-stream")

        with open(file_path, "rb") as f:
            data = f.read()

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    parser = argparse.ArgumentParser(description="Diretta Appliance Onboarding UI")
    parser.add_argument("--profile", required=True)
    parser.add_argument("--port", type=int, default=8088)
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--state-dir", default=DEFAULT_STATE_DIR)
    args = parser.parse_args()

    profile = load_profile(args.profile)
    OnboardingHandler.profile = profile
    OnboardingHandler.state_dir = args.state_dir

    os.makedirs(os.path.dirname(profile["config_path"]), exist_ok=True)
    os.makedirs(args.state_dir, exist_ok=True)
    if not os.path.exists(os.path.join(args.state_dir, DEFAULT_STATE_FILE)):
        save_state(args.state_dir, DEFAULT_ONBOARDING_STATE)

    server = HTTPServer((args.bind, args.port), OnboardingHandler)
    print(
        f"[onboarding] {profile.get('product_name', 'Diretta Appliance')} onboarding UI"
    )
    print(f"[onboarding] Listening on http://{args.bind}:{args.port}")
    print(f"[onboarding] Config file: {profile.get('config_path', 'N/A')}")
    print(f"[onboarding] State dir: {args.state_dir}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[onboarding] Shutting down.")
        server.server_close()


if __name__ == "__main__":
    main()
