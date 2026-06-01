# =============================================================================
# annotate-change.R — The annotate_change() function
# =============================================================================
#
# HOW THIS FILE DIFFERS FROM annotate-callout.R:
#
# annotate_callout() is self-contained — one function, one helper, one layer.
# annotate_change() is more complex because it:
#
#   1. Selects TWO rows instead of one (from and to).
#   2. Extracts a numeric value from each row and computes a delta.
#   3. Formats the delta as a human-readable label (percent, absolute, both).
#   4. Picks a color based on the direction of change.
#   5. Returns TWO layers (arrow + label) instead of one.
#
# To keep this file focused on the ggplot2 plumbing, the semantic logic
# (delta computation, label formatting, color selection, input validation)
# lives in R/utils-change.R as internal helpers. This separation has two
# benefits:
#
#   - Each helper is independently testable without needing a ggplot.
#     Pure logic tests are faster and more diagnostic than visual tests.
#   - This file reads as a clear pipeline: validate → extract → compute →
#     build layers. The business logic details are one function call away
#     if you need them.
#
# WHY WE RETURN A LIST OF LAYERS:
#   annotate_callout() returns a single ggpp::geom_label_s() layer, which
#   handles both the arrow and the label internally. annotate_change()
#   needs a segment (arrow between two points) and a label (at the midpoint),
#   which are two separate geoms. ggplot2's + operator handles lists
#   transparently: p + list(geom_segment(...), geom_label(...)) works
#   exactly like adding them individually.
#
# =============================================================================

#' Annotate the change between two data points on a ggplot
#'
#' Draws a straight arrow between two data rows and labels the midpoint
#' with the computed delta. The label is color-coded: dark green for
#' increases, dark red for decreases, grey for no change. Built on top of
#' [ggplot2::annotate()].
#'
#' @param data A data frame. Should be the same data frame used in the
#'   ggplot. Must contain the columns mapped to x and y in the plot's
#'   `aes()`, as well as the column specified in `value`.
#' @param from <[tidy-eval][rlang::args_data_masking]> A filtering
#'   expression that identifies exactly one row of `data` for the start
#'   of the arrow. For example, `quarter == "Q2"`. An error is thrown if
#'   the expression matches zero or more than one row.
#' @param to <[tidy-eval][rlang::args_data_masking]> A filtering
#'   expression that identifies exactly one row of `data` for the end
#'   of the arrow.
#' @param value <[tidy-eval][rlang::args_data_masking]> An unquoted
#'   column name indicating which numeric column to compute the change
#'   on. For example, `value = revenue`.
#' @param format How to format the delta label. One of `"percent"`
#'   (default), `"absolute"`, `"points"`, or `"both"`. Percent change
#'   from a zero base value falls back to absolute with a warning.
#'   Percent change from negative values uses the raw formula and may
#'   be confusing; use `"absolute"` for data that can go negative.
#'   Use `"points"` when the data is already a rate or percentage
#'   (e.g., savings rate, market share) — it labels the difference
#'   in percentage points (e.g., "+9.8 %pts") instead of computing
#'   a misleading percent-of-percent.
#'
#' @return A list of ggplot2 layers (arrow + label) that can be added
#'   to a plot with `+`.
#'
#' @examples
#' library(ggplot2)
#'
#' revenue <- data.frame(
#'   quarter = factor(c("Q1", "Q2", "Q3", "Q4"),
#'                    levels = c("Q1", "Q2", "Q3", "Q4")),
#'   revenue = c(120, 145, 132, 158)
#' )
#'
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(
#'     revenue,
#'     from = quarter == "Q2",
#'     to = quarter == "Q3",
#'     value = revenue
#'   )
#'
#' @export
annotate_change <- function(data, from, to, value, format = "percent") {

  # -- CAPTURE TIDY-EVAL ARGUMENTS ---------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Same enquo() pattern as annotate_callout(), but we have three
  #   tidy-eval arguments instead of one. Each needs to be captured
  #   BEFORE any evaluation happens — if you call enquo() after another
  #   function has already evaluated the argument, you get the result
  #   instead of the expression.

  from_quo  <- rlang::enquo(from)
  to_quo    <- rlang::enquo(to)
  value_quo <- rlang::enquo(value)

  # -- VALIDATE INPUTS ---------------------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Delegating to validate_change_inputs() keeps this function focused
  #   on the happy path. The validator checks data type, format value,
  #   and that the value column exists and is numeric. If anything is
  #   wrong, it throws an error with a clear message.

  validate_change_inputs(data, value_quo, format)

  # -- RESOLVE FROM AND TO ROWS ------------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Identical to annotate_callout()'s row selection — filter the data
  #   using the captured expression, then check for exactly one match.
  #   We do this twice (once for from, once for to) with argument-specific
  #   error messages.

  from_row <- dplyr::filter(data, !!from_quo)
  if (nrow(from_row) == 0L) {
    stop("`from` matched no rows in `data`.", call. = FALSE)
  }
  if (nrow(from_row) > 1L) {
    stop(
      "`from` matched ", nrow(from_row),
      " rows in `data`; it must match exactly one.",
      call. = FALSE
    )
  }

  to_row <- dplyr::filter(data, !!to_quo)
  if (nrow(to_row) == 0L) {
    stop("`to` matched no rows in `data`.", call. = FALSE)
  }
  if (nrow(to_row) > 1L) {
    stop(
      "`to` matched ", nrow(to_row),
      " rows in `data`; it must match exactly one.",
      call. = FALSE
    )
  }

  # -- EXTRACT Y-VALUES --------------------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   rlang::eval_tidy() evaluates the value quosure against each row's
  #   data. If the user wrote value = revenue, this extracts the revenue
  #   column value from from_row and to_row.

  from_val <- rlang::eval_tidy(value_quo, from_row)
  to_val   <- rlang::eval_tidy(value_quo, to_row)

  # -- COMPUTE DELTA AND PICK COLOR --------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Pure-logic helpers do the math and formatting. No ggplot2 code here —
  #   just numbers in, structured result out. This is why we separated the
  #   helpers: compute_delta() and pick_change_color() are already tested
  #   independently in test-utils-change.R.

  delta <- compute_delta(from_val, to_val, format)
  color <- pick_change_color(delta$direction)

  # -- COMPUTE COORDINATES FOR THE LAYERS --------------------------------------
  #
  # WHAT'S HAPPENING:
  #   We need the x and y coordinates of both rows to draw the arrow and
  #   place the midpoint label. The y-values come from `value`. The x-values
  #   come from whatever the plot maps to x — which we inherit from the
  #   parent plot's aes().
  #
  #   For the SEGMENT, we pass the from_row and to_row data directly and
  #   let ggplot2 resolve x/y from the inherited mapping.
  #
  #   For the MIDPOINT LABEL, we need explicit coordinates. We compute
  #   the midpoint of the y-values directly. For x, we use as.numeric()
  #   to handle factor x-axes (factors become integer positions 1, 2, 3...
  #   which is how ggplot2 plots them internally). Passing 2.5 as x
  #   lands midway between the 2nd and 3rd factor level.

  mid_y <- (from_val + to_val) / 2

  # -- DETECT X COLUMN AND EXTRACT COORDINATES ---------------------------------
  #
  # WHAT'S HAPPENING:
  #   We use ggplot2::annotate() for both layers, which needs explicit
  #   coordinate values — it doesn't inherit aes from the parent plot.
  #   We know the y values (from `value`), but we need to figure out
  #   which column holds the x values.
  #
  #   Same heuristic as estimate_nudge() in annotate-callout.R: prefer
  #   a Date column (common x-axis in business charts), otherwise use
  #   the first column that isn't the value column.
  #
  #   For factor x-axes (like quarter = Q1, Q2, Q3, Q4), we convert to
  #   numeric positions with as.numeric(). ggplot2 internally plots
  #   factor levels at integer positions (1, 2, 3...), so passing 2.5
  #   lands the midpoint label exactly between the 2nd and 3rd level.

  value_name <- rlang::as_name(value_quo)

  date_cols <- vapply(data, inherits, logical(1), what = c("Date", "POSIXct"))
  if (any(date_cols)) {
    x_col <- names(which(date_cols))[1]
  } else {
    # No Date column — prefer numeric/factor columns over character, since
    # character columns (like city names) are almost never the x-axis in a
    # chart that also has a numeric value column.
    other_cols <- setdiff(names(data), value_name)
    num_or_factor <- vapply(
      data[other_cols],
      function(col) is.numeric(col) || is.factor(col),
      logical(1)
    )
    if (any(num_or_factor)) {
      x_col <- other_cols[which(num_or_factor)[1]]
    } else {
      x_col <- other_cols[1]
    }
  }

  from_x <- from_row[[x_col]]
  to_x   <- to_row[[x_col]]

  # as.numeric() handles both factor → integer position and Date → days.
  # For Date x-axes, we convert back to Date so ggplot2 doesn't warn
  # about passing a numeric to a Date scale.
  mid_x_num <- (as.numeric(from_x) + as.numeric(to_x)) / 2
  if (inherits(from_x, "Date")) {
    mid_x <- as.Date(mid_x_num, origin = "1970-01-01")
  } else if (inherits(from_x, "POSIXct")) {
    mid_x <- as.POSIXct(mid_x_num, origin = "1970-01-01")
  } else {
    mid_x <- mid_x_num
  }

  # Slight y-offset so the label doesn't sit directly on the arrow line
  y_range <- diff(range(data[[value_name]], na.rm = TRUE))
  label_nudge_y <- y_range * 0.03

  # -- BUILD AND RETURN TWO LAYERS ---------------------------------------------
  #
  # WHAT'S HAPPENING:
  #   Unlike annotate_callout() which returns one ggpp layer, we return
  #   a list of two ggplot2::annotate() layers:
  #
  #   1. A "segment" with an arrowhead connecting from → to. The arrow
  #      color matches the direction (green for up, red for down, grey
  #      for flat).
  #
  #   2. A "label" at the midpoint with the formatted delta string.
  #      Bold text, white background, matching the annotate_callout()
  #      styling.
  #
  #   ggplot2's + operator handles lists: p + list(layer1, layer2)
  #   works exactly like p + layer1 + layer2.

  segment_layer <- ggplot2::annotate(
    "segment",
    x = from_x, xend = to_x,
    y = from_val, yend = to_val,
    arrow = grid::arrow(length = grid::unit(0.15, "inches")),
    colour = color,
    linewidth = 0.6
  )

  label_layer <- ggplot2::annotate(
    "label",
    x = mid_x,
    y = mid_y + label_nudge_y,
    label = delta$label,
    colour = color,
    fill = "white",
    size = 3.5,
    fontface = "bold",
    label.padding = grid::unit(0.3, "lines"),
    label.r = grid::unit(0.15, "lines")
  )

  list(segment_layer, label_layer)
}
