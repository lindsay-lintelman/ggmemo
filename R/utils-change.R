#' Compute the delta between two values
#'
#' @param from_value A single numeric value (the starting point).
#' @param to_value A single numeric value (the ending point).
#' @param format One of "percent", "absolute", "points", or "both".
#'
#' @return A list with `value`, `direction`, and `label`.
#' @noRd
compute_delta <- function(from_value, to_value, format) {
  if (is.na(from_value)) {
    stop("Column value is NA in the `from` row. Cannot compute change.",
         call. = FALSE)
  }
  if (is.na(to_value)) {
    stop("Column value is NA in the `to` row. Cannot compute change.",
         call. = FALSE)
  }

  diff_value <- to_value - from_value

  direction <- if (diff_value > 0) {
    "up"
  } else if (diff_value < 0) {
    "down"
  } else {
    "flat"
  }

  label <- switch(format,
    "percent"  = format_percent(from_value, diff_value, direction),
    "absolute" = format_absolute(diff_value, direction),
    "points"   = format_points(diff_value, direction),
    "both"     = paste0(
      format_percent(from_value, diff_value, direction),
      "\n(",
      format_absolute(diff_value, direction),
      ")"
    )
  )

  list(value = diff_value, direction = direction, label = label)
}


# -- Formatting helpers --------------------------------------------------------

format_percent <- function(from_value, diff_value, direction) {
  if (from_value == 0) {
    warning(
      "Cannot compute percent change from zero. ",
      "Falling back to absolute change.",
      call. = FALSE
    )
    return(format_absolute(diff_value, direction))
  }

  pct <- (diff_value / from_value) * 100
  sign_prefix <- if (direction == "up") "+" else ""
  paste0(sign_prefix, format_number(pct, 1), "%")
}


format_absolute <- function(diff_value, direction) {
  sign_prefix <- if (direction == "up") "+" else ""
  paste0(sign_prefix, format_number(diff_value, 0))
}


format_points <- function(diff_value, direction) {
  sign_prefix <- if (direction == "up") "+" else ""
  paste0(sign_prefix, format_number(diff_value, 1), " %pts")
}


format_number <- function(x, digits) {
  trimws(formatC(x, format = "f", digits = digits, big.mark = ","))
}


#' Validate inputs for annotate_change()
#'
#' @param data A data frame.
#' @param value_quo A quosure capturing the value column expression.
#' @param format A character string.
#' @param colors A named character vector.
#' @return `invisible(TRUE)` if all checks pass.
#' @noRd
validate_change_inputs <- function(data, value_quo, format, colors) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  valid_formats <- c("percent", "absolute", "points", "both")
  if (!format %in% valid_formats) {
    stop(
      "`format` must be one of: ",
      paste(valid_formats, collapse = ", "), ".",
      call. = FALSE
    )
  }

  if (!is.character(colors) || length(colors) != 3L ||
      !all(c("up", "down", "flat") %in% names(colors))) {
    stop(
      '`colors` must be a named character vector: ',
      'c(up = "#hex", down = "#hex", flat = "#hex").',
      call. = FALSE
    )
  }

  value_name <- rlang::as_name(value_quo)

  if (!value_name %in% names(data)) {
    stop("Column `", value_name, "` not found in `data`.", call. = FALSE)
  }

  if (!is.numeric(data[[value_name]])) {
    stop(
      "Column `", value_name, "` must be numeric, not ",
      class(data[[value_name]])[1], ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
