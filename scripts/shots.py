"""Render terminal captures (PNG) from the recorded logs in docs/logs.

Each capture picks command blocks ("$ cmd" + its output) from one log by regex,
so every pixel comes from a real run. Usage: python scripts/shots.py [name ...]
"""
import html
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOGS = ROOT / "docs" / "logs"
OUT = ROOT / "docs" / "screenshots"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PROMPT = "samir@ensp461-lab2:~/ensp461-lab2$"
COLS = 116
MAX_OUTPUT_LINES = 26  # per block; longer output is cut with a marker

# Build/pull progress lines that carry no information in a figure.
NOISE = re.compile(r"^(#\d+ (sha256|extracting|\[internal\]|transferring|resolve|\d+\.\d+s)|#\d+ \[auth\])")

# name -> (log file, [command regexes], optional output filter regex)
SHOTS = {
    "q0-toolchain": ("q0-setup.log", [r"os-release", r"usermod", r"compose version", r"kubectl", r"minikube"]),
    "q0-retry": ("q0-retry.log", [r"jdk-headless", r"jenkins >/dev/null", r"pytest"]),
    "q1-build": ("q1-build-run.log", [r"^docker build -f"], r"^#\d+ \[\d/\d\]|^#\d+ (DONE|CACHED|naming|writing)|^#\d+ exporting"),
    "q1-layers": ("q1-build-run.log", [r"^docker images", r"^docker history", r"RootFS"]),
    "q1-run": ("q1-build-run.log", [r"^docker run", r"^docker ps", r"curl -s localhost:5000/$", r"/health", r"exec lab2-web id", r"docker top", r"health=", ]),
    "q1-cache": ("q1-build-run.log", [r"^touch app"]),
    "q2-lifecycle": ("q2-manage.log", [r"docker ps --filter", r"docker stop", r"ps -a", r"docker start", r"restart lab2-web", r"/health", r"docker rm -f lab2-web"]),
    "q2-registry": ("q2-manage.log", [r"run -d --name lab2-registry", r"docker tag", r"docker images", r"docker push", r"tags/list", r"docker rmi", r"docker pull"]),
    "q2-compose": ("q2-manage.log", [r"compose", r"visits"]),
    "q3-layer": ("q3-storage.log", [r"s-layer"]),
    "q3-volume": ("q3-storage.log", [r"lab2-notes", r"s-vol"]),
    "q3-bind": ("q3-storage.log", [r"shared\.txt"]),
    "q4-network": ("q4-network.log", [r"network create", r"--network lab2-net", r"name n-c", r"inspect", r"ping"]),
    "q5-cluster": ("q5-k8s.log", [r"minikube start", r"network connect", r"minikube status", r"get nodes"]),
    "q5-deploy": ("q5-k8s.log", [r"apply", r"rollout status", r"get deployment", r"get pods", r"describe"]),
    "q5-service": ("q5-k8s.log", [r"curl", r"for i in"]),
    "q6-update": ("q6-rollout.log", [r"docker build", r"history", r"set image .*2\.0\.1", r"rollout status", r"^probe", r"get rs", r"curl"], None, (0, 7)),
    "q6-bad-rollback": ("q6-rollout.log", [r"9\.9\.9", r"rollout status", r"get pods", r"curl", r"history", r"undo", r"^probe"], None, (7, 16)),
    "q6-scaling": ("q6-rollout.log", [r"scale", r"rollout status", r"get deployment"], None, (16, 99)),
    "q7-setup": ("q7-setup.log", [r"usermod", r"kube/config", r"JAVA_OPTS", r"init.groovy.d", r"systemctl restart", r"api/json", r"curl -sI"]),
    "q7-build2": ("q7-build2.log", [r"api/json", r"consoleText"], r"^build |Started by|Commit message|\[Pipeline\] \{ \(|passed|docker (build|push)|kubectl (apply|set image)|successfully rolled|BODY=|Deployed|Finished"),
    "q7-build3": ("q7-build3.log", [r"api/json", r"rollout history", r"get deployment", r"get pods", r"health", r"tags/list"]),
}


def blocks(log):
    """Split a rec.sh log into (command, output lines) blocks."""
    out, cur = [], None
    for line in log.read_text(errors="replace").replace("\r", "\n").splitlines():
        if line.startswith("$ "):
            cur = (line[2:], [])
            out.append(cur)
        elif cur is not None:
            cur[1].append(line)
    return [(c, [l for l in o if not NOISE.match(l)]) for c, o in out]


def wrap(text, first=COLS):
    """Split into terminal rows; the first row may be shorter (it follows the prompt)."""
    rows = [text[:first]]
    rows += [text[i:i + COLS] for i in range(first, len(text), COLS)]
    return rows


def render(name, spec):
    logname, patterns = spec[0], spec[1]
    keep = re.compile(spec[2]) if len(spec) > 2 and spec[2] else None
    lo, hi = spec[3] if len(spec) > 3 else (0, 10**6)
    rows = []
    picked = [b for b in blocks(LOGS / logname)[lo:hi] if any(re.search(p, b[0]) for p in patterns)]
    if not picked:
        raise SystemExit(f"{name}: no blocks matched in {logname}")
    for cmd, output in picked:
        output = [l for l in output if (keep is None or keep.search(l))]
        while output and not output[-1].strip():
            output.pop()
        if len(output) > MAX_OUTPUT_LINES:
            cut = len(output) - MAX_OUTPUT_LINES
            output = output[:MAX_OUTPUT_LINES] + [f"... ({cut} more lines in docs/logs/{logname})"]
        first, *rest = wrap(cmd, COLS - len(PROMPT) - 1)
        rows.append(f'<span class="p">{html.escape(PROMPT)}</span> <span class="c">{html.escape(first)}</span>')
        rows += [f'<span class="c">{html.escape(r)}</span>' for r in rest]
        for line in output:
            rows += [html.escape(r) for r in wrap(line)]
    page = f"""<!doctype html><meta charset="utf-8"><style>
body{{margin:0;background:#fff}}
.w{{margin:14px;border-radius:9px;overflow:hidden;border:1px solid #c9c9c9;box-shadow:0 4px 14px rgba(0,0,0,.16)}}
.t{{background:#e7e7e7;height:30px;display:flex;align-items:center;padding:0 12px;border-bottom:1px solid #cfcfcf;
font:13px -apple-system,Helvetica,sans-serif;color:#4a4a4a}}
.d{{width:12px;height:12px;border-radius:50%;margin-right:8px;background:#c4c4c4}}
.t b{{flex:1;text-align:center;font-weight:500;margin-right:60px}}
pre{{margin:0;background:#1d1f21;color:#d6d6d6;padding:12px 14px 14px;font:13px/1.42 Menlo,monospace;white-space:pre}}
.p{{color:#8fbf6a;font-weight:bold}}.c{{color:#ffffff}}
</style><div class="w"><div class="t"><span class="d"></span><span class="d"></span><span class="d"></span>
<b>samir@ensp461-lab2: ~/ensp461-lab2</b></div><pre>{chr(10).join(rows)}</pre></div>"""
    height = 30 + 28 + 26 + int(len(rows) * 13 * 1.42) + 4
    width = int(COLS * 8.15) + 28 + 28 + 2
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(page)
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / f"{name}.png"
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
                    f"--window-size={width},{height}", f"--screenshot={target}", f"file://{f.name}"],
                   check=True, capture_output=True)
    Path(f.name).unlink()
    print(f"{target.relative_to(ROOT)}  ({len(rows)} lines)")


if __name__ == "__main__":
    for n in sys.argv[1:] or SHOTS:
        if (LOGS / SHOTS[n][0]).exists():
            render(n, SHOTS[n])
