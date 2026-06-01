# =============================================================================
# annotate-callout.R — The annotate_callout() function
# =============================================================================
#
# FILE NAMING CONVENTION:
#   Tidyverse style uses kebab-case for R source files: annotate-callout.R,
#   not annotateCallout.R or annotate_callout.R. The function NAME inside
#   uses snake_case (annotate_callout), but the filename uses kebab-case.
#   This is a convention, not a requirement — R doesn't care about filenames.
#
# WHY ggplot2:: AND ggpp:: PREFIXES?
#   Inside a package, you must refer to functions from other packages using
#   the explicit namespace prefix: ggplot2::aes(), ggpp::geom_label_s(), etc.
#   This is different from interactive R, where library(ggplot2) lets you
#   call aes() directly. In package code, library() is forbidden — it would
#   change the user's search path as a side effect. The :: operator tells R
#   exactly where to find each function, with no side effects.
#
#   You CAN avoid :: by adding @importFrom tags (e.g., @importFrom ggplot2 aes),
#   which register the import in NAMESPACE. But :: is more explicit and
#   easier to read — you always know where a function comes from. The
#   tidyverse style guide recommends :: for most cases, reserving @importFrom
#   for operators and very frequently used functions.
#
# WHAT @export DOES:
#   The @export tag tells roxygen2 to add this function to the NAMESPACE file,
#   making it available to users who load your package with library(ggmemo).
#   Without @export, the function would be "internal" — callable within
#   the package but invisible to users. They could still access it via
#   ggmemo:::annotate_callout() (triple colon), but that's not intended.
#
# WHY @examples MATTER:
#   R CMD check actually RUNS your @examples as a test. If they error, the
#   check fails. This means examples serve double duty: they're documentation
#   for the user AND a basic integration test. Every exported function should
#   have at least one working example. The \dontrun{} wrapper skips execution
#   during check — use it only for examples with side effects (network calls,
#   file writes), not for normal usage.
#
# =============================================================================

#' Add a callout annotation to a ggplot
#'
#' Points at a specific data row with an arrow and label. The callout
#' consists of a text label inside a rounded box, connected to the target
#' data point by a line segment with an arrowhead. Built on top of
#' [ggpp::geom_label_s()].
#'
#' @param data A data frame. Should be the same data frame used in the
#'   ggplot, or a subset of it. Must contain the columns mapped to x and y
#'   in the plot's `aes()`.
#' @param where <[tidy-eval][rlang::args_data_masking]> A filtering
#'   expression that identifies exactly one row of `data`. For example,
#'   `year == 2020` or `quarter == "Q4" & region == "West"`. An error is
#'   thrown if the expression matches zero or more than one row.
#' @param label A single character string for the annotation text.
#' @param position Where to place the label relative to the data point.
#'   One of `"top-right"` (default), `"top-left"`, `"bottom-right"`, or
#'   `"bottom-left"`.
#' @param nudge Optional numeric vector of length 2 (`c(x, y)`) giving
#'   explicit nudge amounts in data units. Overrides the automatic nudge
#'   heuristic, which estimates 5% of the x and y data ranges. The
#'   heuristic works well when `data` contains only the plotted columns;
#'   if `data` has many numeric columns (like [ggplot2::economics]),
#'   passing a two-column subset or setting `nudge` explicitly avoids
#'   the heuristic picking the wrong column's range.
#'
#' @return A ggplot2 layer that can be added to a plot with `+`.
#'
#' @examples
#' library(ggplot2)
#'
#' p <- ggplot(economics, aes(x = date, y = unemploy)) +
#'   geom_line()
#'
#' p + annotate_callout(
#'   economics,
#'   where = date == as.Date("2009-10-01"),
#'   label = "Peak unemployment",
#'   position = "top-right"
#' )
#'
#' @export
annotate_callout <- function(data, where, label, position = "top-right",
                             nudge = NULL) {

  # -- INPUT VALIDATION --------------------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Before doing any work, we check that the user gave us valid inputs.
  #   Package functions should fail early with clear messages — not halfway
  #   through execution with a cryptic error from some internal function.
  #
  # WHY call. = FALSE?
  #   By default, stop() includes the function call in the error message,
  #   like: "Error in annotate_callout(...): ...". That's noisy and often
  #   confusing for users. call. = FALSE suppresses it, giving a cleaner
  #   message: "Error: `data` must be a data frame."
  #   This is standard practice in tidyverse packages.

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (!is.character(label) || length(label) != 1L) {
    stop("`label` must be a single character string.", call. = FALSE)
  }

  valid_positions <- c("top-right", "top-left", "bottom-right", "bottom-left")
  if (!position %in% valid_positions) {
    stop(
      "`position` must be one of: ",
      paste(valid_positions, collapse = ", "), ".",
      call. = FALSE
    )
  }

  # -- ROW SELECTION VIA TIDY EVALUATION ---------------------------------------
  #
  # WHAT'S HAPPENING:
  #   The user writes: where = date == as.Date("2009-10-01")
  #   R normally would try to evaluate that expression RIGHT HERE, which
  #   would fail because 'date' isn't a variable in the calling environment.
  #   Instead, we need to CAPTURE the expression unevaluated, then evaluate
  #   it later against the data frame — where 'date' IS a column.
  #
  #   rlang::enquo(where) captures the user's expression as a "quosure" —
  #   think of it as a frozen expression plus the environment it came from.
  #
  #   dplyr::filter(data, !!where_quo) evaluates that frozen expression.
  #   The !! (called "bang-bang") injects the quosure into filter(), which
  #   then evaluates it against the data frame's columns.
  #
  #   This two-step capture-then-inject pattern is called Non-Standard
  #   Evaluation (NSE). It's the same mechanism behind dplyr::filter()
  #   and ggplot2::aes(). Hard to implement, but makes the user-facing
  #   API feel natural.

  where_quo <- rlang::enquo(where)
  row <- dplyr::filter(data, !!where_quo)

  if (nrow(row) == 0L) {
    stop("`where` matched no rows in `data`.", call. = FALSE)
  }
  if (nrow(row) > 1L) {
    stop(
      "`where` matched ", nrow(row),
      " rows in `data`; it must match exactly one.",
      call. = FALSE
    )
  }

  # -- COMPUTE NUDGE VALUES FROM DATA RANGES -----------------------------------
  #
  # WHAT'S HAPPENING:
  #   geom_label_s() positions the label by "nudging" it away from the data
  #   point — nudge_x moves it horizontally, nudge_y moves it vertically.
  #   But nudge values are in DATA UNITS (days for a date axis, dollars for
  #   a dollar axis, etc.), so a fixed nudge like "500" would be way too
  #   big for some charts and invisible on others.
  #
  #   If the user passed an explicit nudge = c(x, y), we use that directly.
  #   Otherwise we fall back to the heuristic: Date columns are usually the
  #   x-axis in business charts, and the first numeric column is usually y.
  #   We compute 5% of each column's range as the nudge.
  #
  #   The heuristic works well when data has just an x and y column. For
  #   wide data frames with many numeric columns (like ggplot2::economics),
  #   the heuristic may pick the wrong column's range — that's when the
  #   explicit nudge argument saves you.

  if (!is.null(nudge)) {
    if (!is.numeric(nudge) || length(nudge) != 2L) {
      stop("`nudge` must be a numeric vector of length 2: c(x, y).",
           call. = FALSE)
    }
    nudges <- c(x = nudge[1], y = nudge[2])
  } else {
    nudges <- estimate_nudge(data)
  }

  # Map the position string ("top-right", etc.) to sign multipliers.
  # "top" means positive y nudge (label above the point).
  # "right" means positive x nudge (label to the right of the point).
  signs <- switch(position,
    "top-right"    = c( 1,  1),
    "top-left"     = c(-1,  1),
    "bottom-right" = c( 1, -1),
    "bottom-left"  = c(-1, -1)
  )

  # -- BUILD AND RETURN THE GGPLOT2 LAYER --------------------------------------
  #
  # WHAT'S HAPPENING:
  #   ggpp::geom_label_s() creates a ggplot2 "layer" — the same kind of
  #   object that geom_line() or geom_point() returns. The user adds it
  #   to their plot with +, just like any other geom.
  #
  #   Key arguments:
  #   - data = row: only plot this one data point (the row we filtered to)
  #   - mapping = aes(label = .env$label): the label text. .env$ tells
  #     ggplot2 "look in the function's environment for a variable called
  #     label" — NOT in the data frame. Without .env$, ggplot2 would look
  #     for a column named "label" in the data.
  #   - nudge_x / nudge_y: how far to offset the label from the point
  #   - arrow: draws an arrowhead on the connecting segment
  #   - The remaining arguments are styling: text size, colors, label box
  #     appearance. These are our "tasteful defaults."
  #
  #   No explicit return() needed — R functions return their last expression.

  ggpp::geom_label_s(
    data = row,
    mapping = ggplot2::aes(label = .env$label),
    nudge_x = signs[1] * nudges[["x"]],
    nudge_y = signs[2] * nudges[["y"]],
    arrow = grid::arrow(length = grid::unit(0.15, "inches")),
    size = 3.5,
    colour = "grey20",
    fill = "white",
    alpha = 0.9,
    label.padding = grid::unit(0.25, "lines"),
    label.r = grid::unit(0.15, "lines"),
    segment.linewidth = 0.5
  )
}


# =============================================================================
# estimate_nudge() — Internal helper to compute nudge values
# =============================================================================
#
# NOT EXPORTED (no @export tag). This function is internal — only callable
# inside the package. Users never see or call it directly.
#
# WHY A SEPARATE FUNCTION?
#   Extracting this logic into a helper keeps annotate_callout() focused on
#   its main job. It also makes the nudge logic independently testable —
#   we could write unit tests for estimate_nudge() without needing a full
#   ggplot. In R packages, internal helpers are common; they live in R/
#   files and are available to all functions in the package.
#
# THE HEURISTIC:
#   Business charts are usually time series: Date on x, numeric on y.
#   We look for a Date column to estimate the x-axis range, and the first
#   numeric column for the y-axis range. Then we return 5% of each range
#   as the nudge amount. 5% is enough to visually separate the label from
#   the point without pushing it too far away.
#
#   If there's no Date column (e.g., a scatter plot), we fall back to the
#   first two numeric columns. If we really can't figure it out, we
#   default to 1 — a safe fallback that at least moves the label.
# =============================================================================

estimate_nudge <- function(data, fraction = 0.05) {
  date_cols <- vapply(
    data, inherits, logical(1), what = c("Date", "POSIXct")
  )
  num_cols <- vapply(data, is.numeric, logical(1))

  # X-axis nudge: prefer Date column range (common in business charts)
  if (any(date_cols)) {
    first_date <- data[[which(date_cols)[1]]]
    x_range <- as.numeric(diff(range(first_date, na.rm = TRUE)))
  } else if (any(num_cols)) {
    first_num <- data[[which(num_cols)[1]]]
    x_range <- diff(range(first_num, na.rm = TRUE))
  } else {
    x_range <- 1
  }

  # Y-axis nudge: first numeric column that ISN'T the Date column
  non_date_num <- num_cols & !date_cols
  if (any(non_date_num)) {
    first_y <- data[[which(non_date_num)[1]]]
    y_range <- diff(range(first_y, na.rm = TRUE))
  } else if (any(num_cols)) {
    first_num <- data[[which(num_cols)[1]]]
    y_range <- diff(range(first_num, na.rm = TRUE))
  } else {
    y_range <- 1
  }

  c(x = x_range * fraction, y = y_range * fraction)
}
