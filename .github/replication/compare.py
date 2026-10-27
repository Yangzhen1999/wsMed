"""Compare analysis stages and displayed results without changing any reference."""
import csv
import itertools
import json
from pathlib import Path
import re
import sys
from table_comparison import (ABS_TOL, REL_TOL, case_rows, index_rows,
                              numerically_equal, signature)

inputs = Path(__file__).resolve().parent
source, output = map(Path, sys.argv[1:3])
output.mkdir(parents=True, exist_ok=True)
partial = "--allow-partial" in sys.argv
baseline_path = (Path(sys.argv[sys.argv.index("--baseline") + 1])
                 if "--baseline" in sys.argv else inputs / "candidate-baseline.json")
baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
if baseline.get("schema_version") != 1:
    raise RuntimeError("Unsupported candidate baseline schema")


def compact(x):
    return re.sub(r"\s+", "", x)


def cells(row):
    return [compact(c) for c in row.strip()[1:-1].split("|")]


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
for name, case in cases.items():
    if set(case["fits"]) != {"example1", "example2_pc", "example2_ud", "example3"}:
        raise RuntimeError(f"Missing or unexpected fitted models: {name}")
expected = {f"{profile}-{os}-latest"
            for profile in ("reference-core", "current-cran")
            for os in ("ubuntu", "windows", "macos")}
missing = sorted(expected - set(cases))
stages = ("imputations", "pooled_mean", "pooled_covariance", "mc_preview",
          "marginal_mc_preview", "parameter_tables", "conditional_tables", "standardization_diagnostics")
stage_comparisons, table_comparisons, changed_rows = [], [], []
numerical_comparisons, numerical_failures = [], []
indexed = {name: index_rows(*case_rows(case))[0] for name, case in cases.items()}
missing_precision = [name for name, case in cases.items()
                     if any("printed_precise" not in fit for fit in case["fits"].values())]
precise = {name: index_rows(*case_rows(case, "printed_precise"))[0]
           for name, case in cases.items() if name not in missing_precision}
for name, rows in precise.items():
    if rows.keys() != indexed[name].keys():
        raise RuntimeError(f"Normal and precise table identities differ: {name}")

baseline_comparisons, baseline_failures = [], []
for name, rows in precise.items():
    profile = cases[name]["environment"]["profile"]
    reference = index_rows(*case_rows(baseline["profiles"][profile], "printed_precise"))[0]
    failed = [key for key in sorted(rows.keys() | reference.keys())
              if key not in rows or key not in reference or
              not numerically_equal(rows[key], reference[key])]
    baseline_comparisons.append(dict(environment=name, profile=profile,
        reference_rows=len(reference), current_rows=len(rows), mismatched_rows=len(failed)))
    baseline_failures.extend(dict(environment=name, row=str(key),
        baseline_row=reference.get(key), current_row=rows.get(key)) for key in failed)


for left, right in itertools.combinations(sorted(cases), 2):
    a, b = cases[left], cases[right]
    same_profile = a["environment"]["profile"] == b["environment"]["profile"]
    for name in a["fits"]:
        for stage in stages:
            delta, structure = distance(a["fits"][name][stage], b["fits"][name][stage])
            stage_comparisons.append(dict(left=left, right=right, same_profile=same_profile,
                example=name, stage=stage, max_absolute_difference=delta,
                structural_or_text_mismatches=structure))
    ar, br = indexed[left], indexed[right]
    count = len(ar.keys() ^ br.keys())
    text_count = count
    max_delta = 0
    for key in sorted(ar.keys() | br.keys()):
        x, y = ar.get(key), br.get(key)
        if x is None or y is None:
            changed_rows.append(dict(left=left, right=right, row=str(key), left_row=x, right_row=y))
            continue
        sx, sy = signature(x), signature(y)
        delta, structure = distance(sx, sy)
        different = sx != sy
        count += different
        text_count += compact(x) != compact(y)
        max_delta = max(max_delta, delta)
        if different:
            changed_rows.append(dict(left=left, right=right, row=str(key), left_row=x, right_row=y))
    table_comparisons.append(dict(left=left, right=right, same_profile=same_profile,
        left_rows=len(ar), right_rows=len(br), changed_numeric_or_label_rows=count,
        changed_text_rows=text_count, max_displayed_numeric_difference=max_delta))
    if left in precise and right in precise:
        pa, pb = precise[left], precise[right]
        failed = [key for key in sorted(pa.keys() | pb.keys())
                  if key not in pa or key not in pb or not numerically_equal(pa[key], pb[key])]
        numerical_comparisons.append(dict(left=left, right=right, same_profile=same_profile,
            mismatched_rows=len(failed)))
        numerical_failures.extend(dict(left=left, right=right, same_profile=same_profile,
            row=str(key), left_row=pa.get(key), right_row=pb.get(key)) for key in failed)

# Map each manuscript row to the verified historical table, then compare the
# same semantic row in new runs. Mapping is checked rather than guessed by label
# or assumed to remain at the same line after a model changes its parameters.
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
contexts = ["example2_ud" if custom else "example2_pc" if example == 2
            else f"example{example}" for example, custom in locations]
_, historical_keys = index_rows(old_rows, contexts)
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
local_index, _ = index_rows(local, contexts)
for name, case in sorted(cases.items()):
    rows = indexed[name]
    shared = local_index.keys() & rows.keys()
    local_rows.append(dict(environment=name, rows=len(rows),
        added_rows=len(rows.keys() - local_index.keys()),
        removed_rows=len(local_index.keys() - rows.keys()),
        changed_vs_local_candidate=sum(signature(local_index[k]) != signature(rows[k]) for k in shared)))
    for item, i in mapping:
        key = historical_keys[i]
        if key not in rows:
            raise RuntimeError(f"Missing manuscript row for {name}: {key}")
        current = rows[key]
        delta, structure = distance(signature(old_rows[i]), signature(current))
        paper_rows.append(dict(environment=name, example=item["example"],
            manuscript_file=item["manuscript_file"], line=item["line"], label=item["label"],
            old_row=old_rows[i], new_row=current,
            max_displayed_numeric_difference=delta, changed=signature(old_rows[i]) != signature(current)))

write_csv("stage-comparisons.csv", stage_comparisons)
write_csv("table-comparisons.csv", table_comparisons)
write_csv("changed-table-rows.csv", changed_rows)
write_csv("manuscript-comparisons.csv", paper_rows)
write_csv("local-candidate-comparisons.csv", local_rows)
write_csv("numerical-comparisons.csv", numerical_comparisons)
write_csv("numerical-failures.csv", numerical_failures)
write_csv("candidate-baseline-comparisons.csv", baseline_comparisons)
write_csv("candidate-baseline-failures.csv", baseline_failures)
summary = dict(completed_environments=sorted(cases), missing_environments=missing,
    candidate_baseline=dict(source_commit=baseline["source_commit"], status=baseline["status"],
        comparisons=baseline_comparisons, failed_rows=len(baseline_failures)),
    missing_precision=missing_precision,
    numerical_tolerance=dict(absolute=ABS_TOL, relative=REL_TOL, printed_digits=10),
    manuscript_rows_mapped=len(mapping),
    same_profile_table_mismatches=[x for x in table_comparisons
                                  if x["same_profile"] and x["changed_numeric_or_label_rows"]],
    same_profile_numerical_failures=[x for x in numerical_comparisons
                                    if x["same_profile"] and x["mismatched_rows"]],
    comparisons=table_comparisons, local_reference=local_rows,
    warnings={k: v["environment"]["warnings"] for k, v in cases.items()})
(output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
if (missing and not partial) or missing_precision or baseline_failures or summary["same_profile_numerical_failures"]:
    raise SystemExit("Replication comparison detected missing runs/precision, cross-platform or candidate-baseline differences.")
