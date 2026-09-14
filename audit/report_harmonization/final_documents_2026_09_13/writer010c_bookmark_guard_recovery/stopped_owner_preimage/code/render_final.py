"""One pinned final-document QA invocation, never an assembly."""
from pathlib import Path
from hashlib import sha256
import os
import subprocess
import time
import json

OUT = Path(__file__).resolve().parents[1]
PYTHON = "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
RENDER = "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py"
SOFFICE = "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice"
assert sha256(Path(RENDER).read_bytes()).hexdigest() == "876d5993324e2faaaa96a68a4f7504642e9a07e6df265b385b2baa03b231369e"
assert sha256(Path(SOFFICE).read_bytes()).hexdigest() == "81c7db1c6dbcdd606d95abef337b4529aeda6a4fa1cf23a5a567f9c5655c8b66"
main = OUT / "deliverables/Nature_Health_manuscript.docx"
proof = json.loads((OUT / "evidence/patch_proof.json").read_text())
assert sha256(main.read_bytes()).hexdigest() == proof["output_sha256"]
record_path = OUT / "evidence/render_execution.json"
assert not record_path.exists(), "Only one renderer invocation is authorized"
command = [PYTHON, RENDER, str(main), "--output_dir", str(OUT / "qa/main"), "--dpi", "150", "--emit_pdf", "--verbose"]
record = {"command": command, "started": time.time(), "status": "running", "input_sha256": proof["output_sha256"],
          "renderer_sha256": sha256(Path(RENDER).read_bytes()).hexdigest(), "only_permitted_soffice": SOFFICE}
record_path.write_text(json.dumps(record, indent=2))
env = os.environ.copy()
env["PATH"] = str(Path(SOFFICE).parent) + os.pathsep + env.get("PATH", "")
env["PYTHONDONTWRITEBYTECODE"] = "1"
with (OUT / "evidence/render.log").open("x") as log:
    result = subprocess.run(command, cwd=OUT, env=env, stdout=log, stderr=subprocess.STDOUT)
record.update({"status": "complete" if result.returncode == 0 else "failed", "exit_code": result.returncode,
               "ended": time.time(), "input_unchanged_after_render": sha256(main.read_bytes()).hexdigest() == proof["output_sha256"]})
record_path.write_text(json.dumps(record, indent=2))
print(json.dumps(record, indent=2))
raise SystemExit(result.returncode)
