"""Compare analysis stages and displayed results without changing any reference."""
import csv
import itertools
import json
from pathlib import Path
import re
import sys

inputs = Path(__file__).resolve().parent
source, output = map(Path, sys.argv[1:3])
output.mkdir(parents=True, exist_ok=True)
partial = "--allow-partial" in sys.argv
number = re.compile(r"^-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$")


def compact(x):
    return re.sub(r"\s+", "", x)


def cells(row):
    return [compact(c) for c in row.strip()[1:-1].split("|")]


def table_rows(lines):
    return [x for x in lines if x.startswith("|")]


def signature(row):
    # Signed zero is numerically equal; the raw text is retained separately.
    return [float(x) if number.fullmatch(x) else x for x in cells(row)]


def distance(a, b):
    """Return maximum numeric difference and structural/text mismatch count."""
    if isinstance(a, (float, int)) and isinstance(b, (float, int)):
        return abs(a - b), 0
    if isinstance(a, dict) and isinstance(b, dict):
        keys = set(a) & set(b)
        parts = [distance(a[k], b[k]) for k in keys]
        return max([v[0] for v in parts] + [0]), sum(v[1] for v in parts) + len(set(a) ^ set(b))
    if isinstance(a, list) and isinstance(b, list):
        parts = [distance(x, y) for x, y in zip(a, b)]
        return max([v[0] for v in parts] + [0]), sum(v[1] for v in parts) + abs(len(a) - len(b))
    return 0, int(a != b)


def write_csv(name, rows):
    if not rows:
        (output / name).write_text("", encoding="utf-8")
        return
    with (output / name).open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


cases = {p.parent.name: json.loads(p.read_text(encoding="utf-8-sig"))
         for p in source.glob("*/snapshot.json")}
expected = {f"{profile}-{os}-latest"
            for profile in ("reference-core", "current-cran")
            for os in ("ubuntu", "windows", "macos")}
missing = sorted(expected - set(cases))
stages = ("imputations", "pooled_mean", "pooled_covariance", "mc_preview",
          "parameter_tables", "conditional_tables", "standardization_diagnostics")
stage_comparisons, table_comparisons, changed_rows = [], [], []


def flattened_tables(case):
    return [row for fit in case["fits"].values() for row in table_rows(fit["printed"])]


for left, right in itertools.combinations(sorted(cases), 2):
    a, b = cases[left], cases[right]
    same_profile = a["environment"]["profile"] == b["environment"]["profile"]
    for name in a["fits"]:
        for stage in stages:
            delta, structure = distance(a["fits"][name][stage], b["fits"][name][stage])
            stage_comparisons.append(dict(left=left, right=right, same_profile=same_profile,
                example=name, stage=stage, max_absolute_difference=delta,
                structural_or_text_mismatches=structure))
    ar, br = flattened_tables(a), flattened_tables(b)
    count = abs(len(ar) - len(br))
    text_count = count
    max_delta = 0
    for i, (x, y) in enumerate(zip(ar, br), 1):
        sx, sy = signature(x), signature(y)
        delta, structure = distance(sx, sy)
        different = sx != sy
        count += different
        text_count += compact(x) != compact(y)
        max_delta = max(max_delta, delta)
        if different:
            changed_rows.append(dict(left=left, right=right, row=i, left_row=x, right_row=y))
    table_comparisons.append(dict(left=left, right=right, same_profile=same_profile,
        left_rows=len(ar), right_rows=len(br), changed_numeric_or_label_rows=count,
        changed_text_rows=text_count, max_displayed_numeric_difference=max_delta))

# Map each manuscript row to the verified historical table, then compare the
# same indexed row in new runs. Mapping is checked rather than guessed by label.
old_lines = (inputs / "submitted-results.txt").read_text(encoding="utf-8-sig").splitlines()
old_rows, locations = [], []
example, custom = None, False
for line in old_lines:
    if line.startswith("EXAMPLE "):
        example = int(line[8])
        custom = "(UD)" in line
    if line.startswith("|"):
        old_rows.append(line)
        locations.append((example, custom))
with (inputs / "manuscript-rows.csv").open(encoding="utf-8-sig") as f:
    manuscript = list(csv.DictReader(f))
mapping = []
for item in manuscript:
    values = [float(x.strip()) for x in item["manuscript_values"].split(";")]
    matches = []
    for i, (row, loc) in enumerate(zip(old_rows, locations)):
        cc = cells(row)
        nums = [float(c) for c in cc if re.fullmatch(r"-?\d+\.\d+", c)]
        # The manuscript's probe-contrast label is in column 2; other
        # manuscript row labels are in column 1 (not regression label aliases).
        label_matches = (cc[0] == "indirect_effect_1" and item["label"] == cc[1]
                         if item["label"].startswith("(") else item["label"] == cc[0])
        if loc == (int(item["example"]), False) and label_matches and nums == values:
            matches.append(i)
    if len(matches) != 1:
        raise RuntimeError(f"Ambiguous/missing manuscript mapping: {item}, matches={matches}")
    mapping.append((item, matches[0]))

paper_rows, local_rows = [], []
local = (inputs / "candidate-tables.txt").read_text(encoding="utf-8").splitlines()
if len(local) != len(old_rows):
    raise RuntimeError("Historical and local candidate table structures differ")
for name, case in sorted(cases.items()):
    rows = flattened_tables(case)
    if len(rows) != len(old_rows):
        raise RuntimeError(f"Changed output structure for {name}: {len(rows)} rows")
    local_rows.append(dict(environment=name, rows=len(rows),
        changed_vs_local_candidate=sum(signature(a) != signature(b) for a, b in zip(local, rows))))
    for item, i in mapping:
        delta, structure = distance(signature(old_rows[i]), signature(rows[i]))
        paper_rows.append(dict(environment=name, example=item["example"],
            manuscript_file=item["manuscript_file"], line=item["line"], label=item["label"],
            old_row=old_rows[i], new_row=rows[i],
            max_displayed_numeric_difference=delta, changed=signature(old_rows[i]) != signature(rows[i])))

write_csv("stage-comparisons.csv", stage_comparisons)
write_csv("table-comparisons.csv", table_comparisons)
write_csv("changed-table-rows.csv", changed_rows)
write_csv("manuscript-comparisons.csv", paper_rows)
write_csv("local-candidate-comparisons.csv", local_rows)
summary = dict(completed_environments=sorted(cases), missing_environments=missing,
    manuscript_rows_mapped=len(mapping),
    same_profile_table_mismatches=[x for x in table_comparisons
                                  if x["same_profile"] and x["changed_numeric_or_label_rows"]],
    comparisons=table_comparisons, local_reference=local_rows,
    warnings={k: v["environment"]["warnings"] for k, v in cases.items()})
(output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
if (missing and not partial) or summary["same_profile_table_mismatches"]:
    raise SystemExit("Replication comparison detected missing runs or cross-platform table differences.")
