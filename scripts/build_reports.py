"""Build reports/*.pdf from docs/report-src/*.md with headless Chrome.

Usage: python scripts/build_reports.py [q1 ...]
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "report-src"
OUT = ROOT / "reports"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
HEADER = {
    "course": "ENSP461 - DevOps &amp; Automation | Lab 2: Containerization &amp; Kubernetes Orchestration",
    "name": "Samir Kumar Gupta",
    "roll": "2301730243",
    "env": "Ubuntu 24.04.5 LTS (OrbStack VM, arm64)",
}
CSS = """
@page { size: A4; margin: 16mm 15mm 16mm 15mm; }
body { font: 10.5pt/1.5 "Helvetica Neue", Helvetica, Arial, sans-serif; color: #1b1b1b; }
.hdr { border-bottom: 1.5px solid #1b1b1b; padding-bottom: 6px; margin-bottom: 14px; font-size: 9pt; }
.hdr .c { font-weight: 600; }
.hdr .m { display: flex; gap: 22px; margin-top: 3px; color: #333; }
h1 { font-size: 15pt; margin: 6px 0 8px; }
h2 { font-size: 12pt; margin: 18px 0 6px; break-after: avoid; }
h3 { font-size: 10.5pt; margin: 12px 0 4px; break-after: avoid; }
blockquote { margin: 0 0 10px; padding: 0; color: #1b1b1b; font-weight: 500; }
p { margin: 5px 0 8px; }
pre { background: #f4f4f2; border: 1px solid #e0e0dc; border-radius: 4px; padding: 7px 9px;
      font: 8.4pt/1.42 Menlo, monospace; white-space: pre-wrap; word-break: break-all; break-inside: avoid; }
code { font: 8.8pt Menlo, monospace; background: #f1f1ee; padding: 0 3px; border-radius: 3px; }
pre code { background: none; padding: 0; font-size: inherit; }
figure { margin: 10px 0 14px; break-inside: avoid; text-align: center; }
figure img { max-width: 100%; max-height: 205mm; border: 1px solid #ddd; }
figcaption { font-size: 8.8pt; color: #444; margin-top: 3px; }
table { border-collapse: collapse; margin: 6px 0 10px; font-size: 9.4pt; width: 100%; }
th, td { border: 1px solid #cfcfcf; padding: 4px 7px; text-align: left; vertical-align: top; }
th { background: #f1f1ee; }
ul, ol { margin: 4px 0 8px; padding-left: 20px; }
li { margin: 2px 0; }
"""
FIG = re.compile(r"^!\[(.+?)\]\((.+?)\)\s*$", re.M)


def to_html(md_text):
    # Standalone images become captioned figures.
    md_text = FIG.sub(lambda m: f'<figure><img src="{(ROOT / m[2]).as_uri()}"><figcaption>Fig: {m[1]}</figcaption></figure>', md_text)
    body = markdown.markdown(md_text, extensions=["fenced_code", "tables"])
    h = HEADER
    return f"""<!doctype html><meta charset="utf-8"><style>{CSS}</style>
<div class="hdr"><div class="c">{h['course']}</div><div class="m"><span>Name: {h['name']}</span>
<span>Roll No.: {h['roll']}</span><span>Environment: {h['env']}</span></div></div>{body}"""


def build(src):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(to_html(src.read_text()))
    target = OUT / f"{src.stem}.pdf"
    OUT.mkdir(exist_ok=True)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--allow-file-access-from-files", f"--print-to-pdf={target}", f"file://{f.name}"],
                   check=True, capture_output=True)
    Path(f.name).unlink()
    print(target.relative_to(ROOT))


if __name__ == "__main__":
    for s in sorted(SRC.glob("*.md")):
        if not sys.argv[1:] or s.stem.split("-")[0] in sys.argv[1:]:
            build(s)
