"""Semantic table alignment and numerical checks for the replication audit."""
from collections import Counter
import math
import re

NUMBER = re.compile(r"^-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$")
# Numerical optimization is not bit-identical across BLAS/OS builds. Compare
# ten-decimal output before display rounding; keep all display changes in CSV.
ABS_TOL = 1e-5
REL_TOL = 1e-5


def cells(row):
    return [re.sub(r"\s+", "", c) for c in row.strip()[1:-1].split("|")]


def separator(row):
    return all(re.fullmatch(r":?-+:?", c) for c in cells(row))


def signature(row):
    if separator(row):
        return [":" + (":" if c.endswith(":") else "") for c in cells(row)]
    return [float(c) if NUMBER.fullmatch(c) else c for c in cells(row)]


def numerically_equal(left, right):
    a, b = signature(left), signature(right)
    if len(a) != len(b):
        return False
    return all(math.isclose(x, y, abs_tol=ABS_TOL, rel_tol=REL_TOL)
               if isinstance(x, float) and isinstance(y, float) else x == y
               for x, y in zip(a, b))


def index_rows(rows, contexts):
    """Keys identify fit, header/scale occurrence, and parameter/probe labels.

    Auxiliary parameters may be added or reordered without shifting the paper
    mapping. Repeated headers distinguish raw and standardized tables. Probe
    values remain compared numerically, while their level labels identify rows.
    Duplicate keys are errors, never silently overwritten.
    """
    if len(rows) != len(contexts):
        raise ValueError("Each table row needs a model context")
    counts, indexed, keys = Counter(), {}, []
    table, header = None, None
    for i, (row, context) in enumerate(zip(rows, contexts)):
        if i + 1 < len(rows) and separator(rows[i + 1]):
            header = tuple(cells(row))
            counts[context, header] += 1
            table = (context, header, counts[context, header])
            identity = ("header",)
        elif separator(row):
            identity = ("alignment",)
        else:
            if table is None or table[0] != context:
                raise ValueError(f"Row outside a table: {row}")
            values = cells(row)
            if len(values) != len(header):
                raise ValueError(f"Column count differs from header: {row}")
            end = next((j for j, name in enumerate(header)
                        if name in ("Estimate", "Value")), 1)
            identity = ("data",) + tuple(values[j] for j in range(end)
                                         if header[j] != "W_value")
        key = table + identity
        if key in indexed:
            raise ValueError(f"Ambiguous duplicate table row: {key}")
        indexed[key] = row
        keys.append(key)
    return indexed, keys


def case_rows(case, field="printed"):
    rows, contexts = [], []
    for name, fit in case["fits"].items():
        current = [r for r in fit[field] if r.startswith("|")]
        rows.extend(current)
        contexts.extend([name] * len(current))
    return rows, contexts
