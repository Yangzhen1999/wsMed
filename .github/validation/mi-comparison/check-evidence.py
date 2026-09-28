"""Check retained evidence integrity and the complete, paired attempt grid."""
import csv
import hashlib
import itertools
import json
from pathlib import Path

root = Path(__file__).resolve().parent
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
for name, checksum in manifest["files"].items():
    if hashlib.sha256((root / name).read_bytes()).hexdigest() != checksum:
        raise RuntimeError(f"MI comparison evidence changed: {name}")
with (root / "replicates.csv").open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))
keys = [(int(x["scenario"]), int(x["replicate"]), x["method"], int(x["probe"])) for x in rows]
expected = set(itertools.product(range(5, 9), range(1, 201),
                                ("pmm", "smcfcs", "smcfcs20", "complete"), (-1, 0, 1)))
if len(keys) != len(set(keys)) or set(keys) != expected:
    raise RuntimeError("Missing or duplicate planned simulation attempts")
for row in rows:
    seed = 100000 + 10000 * int(row["scenario"]) + 3 * int(row["replicate"])
    if int(row["data_seed"]) != seed or int(row["mc_seed"]) != seed + 2:
        raise RuntimeError("Paired simulation seeds changed")
failed = {(x["scenario"], x["replicate"], x["method"]) for x in rows if x["error"] != "NA"}
if len(failed) != manifest["analysis_failures"]:
    raise RuntimeError("Failure accounting differs from the manifest")
for method, label in (("smcfcs", "smcfcs_m5"), ("smcfcs20", "smcfcs_m20")):
    warned = {(x["scenario"], x["replicate"]) for x in rows
              if x["method"] == method and "Rejection sampling failed" in x["warning"]}
    if len(warned) != manifest["rejection_warning_analyses"][label]:
        raise RuntimeError("Rejection-sampling warning accounting differs from the manifest")
print("MI comparison: evidence hashes, 3200 paired analysis attempts and seed identities verified.")
