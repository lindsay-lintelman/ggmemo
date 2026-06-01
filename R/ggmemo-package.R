#' @description
#' Add arrows, labels, and change annotations to ggplot2 charts in one
#' line of code. Two functions:
#'
#' - [annotate_callout()]: Point at a data row with an arrow and label.
#' - [annotate_change()]: Show the delta between two rows as percent
#'   change, absolute change, or percentage points.
#'
#' Both return standard ggplot2 layers — add them with `+`.
#'
#' @section Quick reference:
#' \preformatted{
#' # Label a data point
#' annotate_callout(data, where, label, position, nudge, ...)
#'
#' # Show change between two points
#' annotate_change(data, from, to, value, format, colors, ...)
#'
#' format options: "percent" (default), "absolute", "points", "both"
#' }
#'
#' @section Common tasks:
#' \tabular{ll}{
#'   Label a peak or milestone   \tab `annotate_callout(df, where = date == "2024-06-01", label = "Peak")` \cr
#'   Show percent change         \tab `annotate_change(df, from = ..., to = ..., value = sales)` \cr
#'   Show absolute difference    \tab `annotate_change(..., format = "absolute")` \cr
#'   Show percentage point change \tab `annotate_change(..., format = "points")` \cr
#'   Use custom colors           \tab `annotate_change(..., colors = c(up = "#1B9E77", down = "#D95F02", flat = "#999"))` \cr
#'   Override label styling      \tab `annotate_callout(..., size = 4, fill = "lightyellow")` \cr
#' }
#'
#' @section When to use ggmemo:
#' Use ggmemo when you want to annotate a ggplot2 chart with arrows,
#' callout labels, or change annotations without manually computing
#' coordinates, formatting deltas, or positioning text. Common
#' scenarios: quarterly reports, executive dashboards, time-series
#' narration, before/after comparisons.
#'
#' @section When NOT to use ggmemo:
#' - Repelling overlapping labels: use the ggrepel package.
#' - NPC (normalized parent coordinates) positioning: use the ggpp package.
#' - Interactive annotations: use plotly or ggiraph.
#' - Theming or styling: use ggthemes, hrbrthemes, or bbplot.
#'
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .env
## usethis namespace: end
NULL
