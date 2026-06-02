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


#' Detect which column is likely the x-axis
#' @noRd
detect_x_column <- function(data, value_name) {
  date_cols <- vapply(data, inherits, logical(1), what = c("Date", "POSIXct"))
  if (any(date_cols)) {
    return(names(which(date_cols))[1])
  }

  other_cols <- setdiff(names(data), value_name)
  num_or_factor <- vapply(
    data[other_cols],
    function(col) is.numeric(col) || is.factor(col),
    logical(1)
  )
  if (any(num_or_factor)) {
    return(other_cols[which(num_or_factor)[1]])
  }

  other_cols[1]
}
