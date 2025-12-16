# Parse All Possible Indirect Paths from Column Names

Infers every unique mediation chain that can be constructed from a set
of coefficient names following the WsMed naming convention (e.g., `a1`,
`b_1_3`, `d_2_1`, `b3`). The function returns a list; each element
describes one indirect effect:

- `path_name` – canonical name, e.g.\\ `"indirect_effect_1_3"`  
  (mediators are concatenated in the encountered order);

- `coefs` – vector of coefficient names that define the path;

- `mediators` – readable label such as `"M1 M3"`.

## Usage

``` r
get_indirect_paths(col_names)
```

## Arguments

- col_names:

  Character vector of coefficient names (typically
  `colnames(mc_result$thetahatstar)`).

## Value

A list of path descriptors; each element is itself a list with
components `path_name`, `coefs`, and `mediators`. If no valid path
exists, an empty list is returned.

## Details

Internally the function:

1.  identifies all `a`, `b`, and `d` coefficients available in
    `col_names`;

2.  constructs a directed graph from `X → Mi`, `Mi → Y`, and `Mi → Mj`
    edges;

3.  runs a depth-first search from the exposure (*X*) to the outcome
    (*Y*);

4.  converts every node sequence (X → … → Y) into the corresponding
    coefficient sequence.

Duplicate paths (identical mediator ordering) are removed.
