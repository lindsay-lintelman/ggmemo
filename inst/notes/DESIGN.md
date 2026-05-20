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

### `annotate_callout()`

Point at a specific data row with an arrow and label.

```r
annotate_callout(
  data,
  where,
  label,
  nudge = NULL
)
```

| Argument | Type | Purpose |
|----------|------|---------|
| `data` | data.frame | The same data the plot uses (to locate the target row) |
| `where` | expression | A filter expression identifying the row to annotate, e.g. `quarter == "Q4" & year == 2024` |
| `label` | character | The annotation text |
| `nudge` | numeric vector or NULL | Optional (x, y) offset for the label. If NULL, auto-positioned. |

Returns a ggplot2 layer (geom) that can be added with `+`.

### `annotate_change()`

Auto-compute and label the delta between two data rows.

```r
annotate_change(
  data,
  from,
  to,
  mapping = NULL,
  format = "percent"
)
```

| Argument | Type | Purpose |
|----------|------|---------|
| `data` | data.frame | The same data the plot uses |
| `from` | expression | Filter expression for the start row |
| `to` | expression | Filter expression for the end row |
| `mapping` | aes() or NULL | Which aesthetic holds the value to delta (defaults to y) |
| `format` | character | How to format the delta: "percent", "absolute", "both" |

Returns a ggplot2 layer with an arrow connecting the two points and a
formatted label showing the change (e.g., "+23.4%", "-$1.2M").

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
