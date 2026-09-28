"""Verify that the retained numerical evidence matches its provenance manifest."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
manifest = json.loads((root / "study-manifest.json").read_text(encoding="utf-8"))
expected = dict(manifest["files"])
expected["standardization-simulation.R"] = manifest["current_simulation_script_sha256"]
for name, checksum in expected.items():
    actual = hashlib.sha256((root / name).read_bytes()).hexdigest()
    if actual != checksum:
        raise RuntimeError(f"Study evidence checksum mismatch: {name}")
print("Recorded simulation evidence checksums: OK")
