# Changelog

## ggmemo 0.1.0

Initial release. ggmemo adds two functions for annotating ggplot2
business charts without manual coordinate math.

### New features

- [`annotate_callout()`](https://lindsay-lintelman.github.io/ggmemo/reference/annotate_callout.md)
  points at a specific data row with an arrow and label. Supports four
  label positions, automatic or explicit nudge, and `...` pass-through
  for styling.

- [`annotate_change()`](https://lindsay-lintelman.github.io/ggmemo/reference/annotate_change.md)
  draws a color-coded arrow between two data rows and labels the
  midpoint with the computed delta. Supports four format options:
  `"percent"` (default), `"absolute"`, `"points"` (percentage points),
  and `"both"`. Custom colors via the `colors` argument; label styling
  via `...`.

- Both functions use tidy evaluation for row selection (`where`, `from`,
  `to`) — the same syntax as
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).

### Known limitations

- The automatic nudge heuristic in
  [`annotate_callout()`](https://lindsay-lintelman.github.io/ggmemo/reference/annotate_callout.md)
  guesses which columns are x and y from the data frame structure. On
  wide data frames with many numeric columns, use the `nudge` argument
  or pass a two-column subset of the data.

- [`annotate_change()`](https://lindsay-lintelman.github.io/ggmemo/reference/annotate_change.md)
  similarly guesses the x-axis column. The heuristic prefers Date \>
  numeric/factor \> character, but can pick wrong on wide data.

Both limitations are tracked for v0.2
([\#1](https://github.com/lindsay-lintelman/ggmemo/issues/1),
[\#2](https://github.com/lindsay-lintelman/ggmemo/issues/2)).
