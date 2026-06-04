#' Annotate the change between two data points on a ggplot
#'
#' Draws a curved arrow between two data rows and labels the midpoint
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
#' @param colors Named character vector of length 3 with hex color values
#'   for the arrow and label. Names must be `"up"`, `"down"`, and `"flat"`.
#'   Defaults to dark green, dark red, and grey.
#' @param ... Additional arguments passed to the **label** layer
#'   ([ggplot2::annotate()] with `geom = "label"`). Use to override
#'   defaults like `size`, `fontface`, or `fill`. Note: these do not
#'   affect the arrow segment. To change the arrow, use `colors`.
#' @param curvature Numeric value controlling the curve of the arrow.
#'   Positive values curve right, negative values curve left. Defaults
#'   to `-0.2` for a subtle leftward arc. Set to `0` for a straight
#'   arrow.
#'
#' @return A list of ggplot2 layers (arrow + label) that can be added
#'   to a plot with `+`.
#'
#' @concept percent change
#' @concept annotation
#' @concept change annotation
#' @concept annotate ggplot
#' @concept compare data points
#'
#' @seealso [annotate_callout()] to label a single data point.
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
#' # Percent change (default)
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(
#'     revenue,
#'     from = quarter == "Q1",
#'     to = quarter == "Q4",
#'     value = revenue
#'   )
#'
#' # Absolute change
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(
#'     revenue,
#'     from = quarter == "Q1",
#'     to = quarter == "Q4",
#'     value = revenue,
#'     format = "absolute"
#'   )
#'
#' # Percentage points (for data already expressed as rates)
#' rates <- data.frame(
#'   year = 2020:2023,
#'   rate = c(3.5, 8.1, 5.4, 3.7)
#' )
#' ggplot(rates, aes(x = year, y = rate)) +
#'   geom_line() +
#'   geom_point() +
#'   annotate_change(rates, from = year == 2020, to = year == 2021,
#'                   value = rate, format = "points")
#'
#' # Custom colors (e.g., corporate palette)
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(
#'     revenue,
#'     from = quarter == "Q1",
#'     to = quarter == "Q4",
#'     value = revenue,
#'     colors = c(up = "#1B9E77", down = "#D95F02", flat = "#7570B3")
#'   )
#'
#' # Date x-axis (time series) — use nudge on the callout for wide data
#' ggplot(economics, aes(x = date, y = psavert)) +
#'   geom_line() +
#'   annotate_change(
#'     economics,
#'     from = date == as.Date("2005-07-01"),
#'     to = date == as.Date("2012-12-01"),
#'     value = psavert,
#'     format = "points"
#'   )
#'
#' # Showing a decline (red arrow, negative label)
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(
#'     revenue,
#'     from = quarter == "Q2",
#'     to = quarter == "Q3",
#'     value = revenue
#'   )
#'
#' # Multiple change annotations (quarter-over-quarter)
#' ggplot(revenue, aes(x = quarter, y = revenue)) +
#'   geom_col(fill = "grey70", width = 0.6) +
#'   annotate_change(revenue, from = quarter == "Q1",
#'                   to = quarter == "Q2", value = revenue) +
#'   annotate_change(revenue, from = quarter == "Q2",
#'                   to = quarter == "Q3", value = revenue) +
#'   annotate_change(revenue, from = quarter == "Q3",
#'                   to = quarter == "Q4", value = revenue)
#'
#' # Year-over-year growth on a line chart
#' annual <- data.frame(year = 2019:2024,
#'                      revenue = c(80, 65, 72, 95, 110, 128))
#' ggplot(annual, aes(x = year, y = revenue)) +
#'   geom_line() + geom_point() +
#'   annotate_change(annual, from = year == 2019,
#'                   to = year == 2024, value = revenue) +
#'   annotate_callout(annual, where = year == 2020,
#'                    label = "COVID dip", position = "bottom-right")
#'
#' # Combined with annotate_callout() on a time series
#' ggplot(economics, aes(x = date, y = psavert)) +
#'   geom_line() +
#'   annotate_callout(
#'     economics,
#'     where = date == as.Date("2005-07-01"),
#'     label = "All-time low",
#'     nudge = c(365, 1)
#'   ) +
#'   annotate_change(
#'     economics,
#'     from = date == as.Date("2005-07-01"),
#'     to = date == as.Date("2012-12-01"),
#'     value = psavert,
#'     format = "points"
#'   )
#'
#' @export
annotate_change <- function(data, from, to, value, format = "percent",
                            colors = c(up = "#2E7D32", down = "#B22222",
                                       flat = "#808080"),
                            curvature = -0.2,
                            ...) {

  if (missing(value)) {
    stop(
      "`value` is required. Specify which column holds the numeric values ",
      "to compute the change on (e.g., `value = revenue`).",
      call. = FALSE
    )
  }

  from_quo  <- rlang::enquo(from)
  to_quo    <- rlang::enquo(to)
  value_quo <- rlang::enquo(value)

  validate_change_inputs(data, value_quo, format, colors)

  from_row <- filter_to_single_row(data, from_quo, "from")
  to_row   <- filter_to_single_row(data, to_quo, "to")

  from_val <- rlang::eval_tidy(value_quo, from_row)
  to_val   <- rlang::eval_tidy(value_quo, to_row)

  delta <- compute_delta(from_val, to_val, format)
  color <- colors[[delta$direction]]

  mid_y <- (from_val + to_val) / 2

  # Detect x column: prefer Date, then numeric/factor, then first remaining
  value_name <- rlang::as_name(value_quo)
  x_col <- detect_x_column(data, value_name)

  from_x <- from_row[[x_col]]
  to_x   <- to_row[[x_col]]

  if (is.character(from_x)) {
    # Detect date-like strings (e.g., "2024-01-15" from read.csv)
    looks_like_date <- grepl("^\\d{4}-\\d{2}-\\d{2}", from_x)
    if (looks_like_date) {
      tip <- paste0(
        "Tip: this looks like a date. Convert with ",
        "`data$", x_col, " <- as.Date(data$", x_col, ")`."
      )
    } else {
      tip <- paste0(
        "Tip: convert with `data$", x_col, " <- factor(data$", x_col,
        ", levels = unique(data$", x_col, "))` to preserve data order."
      )
    }
    stop(
      "Column `", x_col, "` is a character vector, but annotate_change() ",
      "needs a numeric, factor, or Date x-axis to compute the midpoint.\n",
      tip,
      call. = FALSE
    )
  }

  # Compute midpoint, preserving Date/POSIXct type for the scale
  mid_x_num <- (as.numeric(from_x) + as.numeric(to_x)) / 2
  if (inherits(from_x, "Date")) {
    mid_x <- as.Date(mid_x_num, origin = "1970-01-01")
  } else if (inherits(from_x, "POSIXct")) {
    mid_x <- as.POSIXct(mid_x_num, origin = "1970-01-01")
  } else {
    mid_x <- mid_x_num
  }

  y_range <- diff(range(data[[value_name]], na.rm = TRUE))
  label_nudge_y <- y_range * 0.03

  segment_layer <- ggplot2::annotate(
    "curve",
    x = from_x, xend = to_x,
    y = from_val, yend = to_val,
    arrow = grid::arrow(length = grid::unit(0.2, "inches")),
    colour = color,
    linewidth = 0.8,
    curvature = curvature
  )

  label_defaults <- list(
    geom = "label",
    x = mid_x,
    y = mid_y + label_nudge_y,
    label = delta$label,
    colour = color,
    fill = "white",
    linewidth = 0,
    size = 4,
    fontface = "bold",
    label.padding = grid::unit(0.35, "lines"),
    label.r = grid::unit(0.15, "lines")
  )

  label_args <- utils::modifyList(label_defaults, list(...))
  label_layer <- do.call(ggplot2::annotate, label_args)

  list(segment_layer, label_layer)
}
