# ggmemo design notes

Working design document for v0.1. Not polished — exists so Week 2 starts
with shared context.

## Audience

Business analysts making analytical reports and presentations with ggplot2.
People who know ggplot2 well enough to build charts, but don't want to spend
20 minutes fiddling with arrow coordinates and formatted labels every time
they annotate one.

## Philosophy

- **Built on ggpp, not from scratch.** ggpp already solves precise annotation
  positioning (nudging, NPC coordinates, text repulsion). We add a semantic
  layer on top — our functions call ggpp under the hood.

- **Opinionated defaults.** Tasteful arrow styles, font sizes, and label
  formatting out of the box. The 80% case should need zero customization.

- **Semantic verbs over primitives.** The user says "call out this data point"
  or "show the change between these two rows" — not "draw an arrow from
  (x1, y1) to (x2, y2) with this arrowhead and this label at this offset."

- **Few arguments.** Each function has a small, well-chosen API surface.
  Power users can pass `...` through to the underlying ggpp geoms if they
  need fine control, but the defaults should handle most cases.

## Planned functions (v0.1)

### `annotate_callout()` (IMPLEMENTED — Week 2)

Point at a specific data row with an arrow and label.

```r
annotate_callout(data, where, label, position = "top-right")
```

| Argument | Type | Purpose |
|----------|------|---------|
| `data` | data.frame | The same data the plot uses (to locate the target row) |
| `where` | tidy-eval expression | A filter expression identifying exactly one row, e.g. `date == as.Date("2009-10-01")` |
| `label` | character | A single string for the annotation text |
| `position` | character | One of "top-right", "top-left", "bottom-right", "bottom-left" |

Uses `rlang::enquo()` + `dplyr::filter()` for row selection. Built on
`ggpp::geom_label_s()` with auto-computed nudge values based on data ranges.
Returns a ggplot2 layer.

### `annotate_change()` (Week 3)

Auto-compute and label the delta between two data rows.

```r
annotate_change(data, from, to, mapping, format = "percent")
```

| Argument | Type | Purpose |
|----------|------|---------|
| `data` | data.frame | The same data the plot uses |
| `from` | tidy-eval expression | Filter expression for the start row |
| `to` | tidy-eval expression | Filter expression for the end row |
| `mapping` | aes() | Which aesthetic holds the value to delta (required — e.g. `aes(y = revenue)`) |
| `format` | character | How to format the delta: "percent", "absolute", "both" |

Design decisions from Week 2 mockup review:
- **Straight arrow** connecting the two data points (not curved)
- **Label at midpoint** of the arrow (not floating above)
- **Color-coded text:** dark red (#B22222) for negative changes with minus sign,
  dark green (#2E7D32) for positive changes with plus sign
- **Bold text** in a white label box, matching annotate_callout() styling
- **`mapping` is required** (not optional) — the user must specify which
  column holds the value to compute the delta on, so the calculation is
  always explicit and correct

Returns a list of ggplot2 layers (segment + label) that can be added with `+`.

## Explicit non-goals for v0.1

We are NOT building:

- **A ggplot2 theme.** There are plenty of good business themes (ggthemes,
  hrbrthemes, bbplot). ggmemo is about annotations, not aesthetics.
- **More arrow styles.** ggpp already has configurable arrows. We pick one
  good default and let `...` pass through for customization.
- **NPC positioning helpers.** ggpp handles this. We don't re-expose it.
- **Faceting-aware annotations.** v0.1 assumes single-panel plots. Facet
  support is a possible v0.2 feature.
- **Stat layers or computed aesthetics.** We compute deltas in R code before
  passing to ggpp, not via the ggplot2 stat system. Keeps things simple.

## Known limitations (v0.1)

- **Nudge heuristic guesses wrong on wide data frames.** `annotate_callout()`
  uses `estimate_nudge()` to compute label offset from data ranges, but it
  picks the first numeric column as the y-axis proxy. On data frames with
  many numeric columns (like `economics` or `txhousing`), it may pick a
  column with a very different range than the one actually plotted. Workaround:
  pass `nudge = c(x, y)` explicitly or subset the data to just the plotted
  columns. A proper fix would require access to the parent plot's `aes()`
  mapping, which annotation functions don't have.

- **x-column heuristic in `annotate_change()`.** Similarly guesses which
  column is the x-axis. Prefers Date > numeric/factor > character, but can
  still pick wrong on wide data. Less likely to cause visible problems
  because the midpoint calculation is more forgiving than nudge scaling.

## v0.2 ideas

- Smarter nudge: accept an `aes()` mapping or infer from the plot object.
- `...` pass-through to underlying ggpp/ggplot2 geoms for fine styling control.
- Colorblind mode for `annotate_change()` (blue/orange instead of green/red).
- Faceting-aware annotations.
- `annotate_milestone()` — vertical reference line with label (e.g., "Product launch").
