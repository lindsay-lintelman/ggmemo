#' Add a callout annotation to a ggplot
#'
#' Points at a specific data row with an arrow and label. The callout
#' consists of a text label inside a rounded box, connected to the target
#' data point by a line segment with an arrowhead. Built on top of
#' [ggpp::geom_label_s()].
#'
#' @param data A data frame. Should be the same data frame used in the
#'   ggplot, or a subset of it. Must contain the columns mapped to x and y
#'   in the plot's `aes()`. Note: the automatic nudge heuristic estimates
#'   label offset from the data ranges, but it guesses which columns are
#'   x and y. For data frames with many numeric columns, passing a
#'   two-column subset (e.g., `data[, c("date", "sales")]`) or setting
#'   `nudge` explicitly gives more reliable placement.
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
#' @param ... Additional arguments passed to [ggpp::geom_label_s()].
#'   Use to override defaults like `size`, `colour`, `fill`, `alpha`,
#'   or `arrow`.
#'
#' @return A ggplot2 layer that can be added to a plot with `+`.
#'
#' @concept annotation
#' @concept arrow
#' @concept label
#' @concept callout
#' @concept callout label
#' @concept annotation arrow
#' @concept highlight data point
#' @concept label arrow
#' @concept ggplot annotation
#' @concept annotate ggplot
#'
#' @seealso [annotate_change()] to label the delta between two data points.
#'
#' @examples
#' library(ggplot2)
#'
#' p <- ggplot(economics, aes(x = date, y = unemploy)) +
#'   geom_line()
#'
#' # Basic callout
#' p + annotate_callout(
#'   economics,
#'   where = date == as.Date("2009-10-01"),
#'   label = "Peak unemployment",
#'   position = "top-right"
#' )
#'
#' # With explicit nudge (useful when data has many numeric columns)
#' p + annotate_callout(
#'   economics,
#'   where = date == as.Date("2009-10-01"),
#'   label = "Peak unemployment",
#'   nudge = c(365, 500)
#' )
#'
#' # Customize label appearance via ... (larger text, yellow background)
#' p + annotate_callout(
#'   economics,
#'   where = date == as.Date("2009-10-01"),
#'   label = "Peak unemployment",
#'   nudge = c(365, 500),
#'   size = 5, fill = "lightyellow"
#' )
#'
#' # Mark both the peak and the trough on the same chart
#' p +
#'   annotate_callout(
#'     economics,
#'     where = date == as.Date("2009-10-01"),
#'     label = "Peak",
#'     nudge = c(365, 500)
#'   ) +
#'   annotate_callout(
#'     economics,
#'     where = date == as.Date("2000-01-01"),
#'     label = "Dot-com low",
#'     position = "bottom-right",
#'     nudge = c(365, 500)
#'   )
#'
#' @export
annotate_callout <- function(data, where, label, position = "top-right",
                             nudge = NULL, ...) {

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

  where_quo <- rlang::enquo(where)
  row <- filter_to_single_row(data, where_quo, "where")

  if (!is.null(nudge)) {
    if (!is.numeric(nudge) || length(nudge) != 2L) {
      stop("`nudge` must be a numeric vector of length 2: c(x, y).",
           call. = FALSE)
    }
    nudges <- c(x = nudge[1], y = nudge[2])
  } else {
    nudges <- estimate_nudge(data)
  }

  signs <- switch(position,
    "top-right"    = c( 1,  1),
    "top-left"     = c(-1,  1),
    "bottom-right" = c( 1, -1),
    "bottom-left"  = c(-1, -1)
  )

  defaults <- list(
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

  # User's ... overrides our defaults
  args <- utils::modifyList(defaults, list(...))
  do.call(ggpp::geom_label_s, args)
}


# -- Internal helpers ----------------------------------------------------------

#' Filter a data frame to exactly one row using a tidy-eval expression
#' @noRd
filter_to_single_row <- function(data, quo, arg_name) {
  mask <- rlang::eval_tidy(quo, data)
  if (!is.logical(mask)) {
    stop(
      "`", arg_name, "` must be a logical expression (e.g., `year == 2020`).",
      call. = FALSE
    )
  }
  row <- data[!is.na(mask) & mask, , drop = FALSE]

  if (nrow(row) == 0L) {
    stop("`", arg_name, "` matched no rows in `data`.", call. = FALSE)
  }
  if (nrow(row) > 1L) {
    stop(
      "`", arg_name, "` matched ", nrow(row),
      " rows in `data`; it must match exactly one.",
      call. = FALSE
    )
  }
  row
}


#' Estimate nudge values from data ranges (heuristic)
#' @noRd
estimate_nudge <- function(data, fraction = 0.05) {
  date_cols <- vapply(data, inherits, logical(1), what = c("Date", "POSIXct"))
  num_cols <- vapply(data, is.numeric, logical(1))
  factor_cols <- vapply(data, is.factor, logical(1))

  # For factor x-axes, nudge by a fraction of the inter-level spacing (1 unit)
  # rather than 5% of the total range, which is too small on short axes.
  if (any(factor_cols)) {
    x_range <- 1 / fraction * 0.4
  } else if (any(date_cols)) {
    x_range <- as.numeric(diff(range(data[[which(date_cols)[1]]], na.rm = TRUE)))
  } else if (any(num_cols)) {
    x_range <- diff(range(data[[which(num_cols)[1]]], na.rm = TRUE))
  } else {
    x_range <- 1
  }

  non_date_num <- num_cols & !date_cols & !factor_cols
  if (any(non_date_num)) {
    y_range <- diff(range(data[[which(non_date_num)[1]]], na.rm = TRUE))
  } else if (any(num_cols)) {
    y_range <- diff(range(data[[which(num_cols)[1]]], na.rm = TRUE))
  } else {
    y_range <- 1
  }

  c(x = x_range * fraction, y = y_range * fraction)
}
