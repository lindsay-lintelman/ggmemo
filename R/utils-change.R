# =============================================================================
# utils-change.R — Internal helpers for annotate_change()
# =============================================================================
#
# WHY A SEPARATE FILE?
#   The tidyverse convention is to put internal helpers in utils-*.R files,
#   named after the feature they support. This keeps annotate-change.R
#   focused on ggplot2 plumbing while the pure business logic lives here.
#   It also makes these helpers easy to test in isolation — you can test
#   compute_delta() without ever creating a ggplot.
#
# WHAT @noRd DOES:
#   Normally, roxygen2 generates a .Rd help file for every documented
#   function. @noRd ("no Rd") suppresses that — the function gets roxygen
#   comments in the source (useful for developers reading the code) but
#   no user-facing help page. Use @noRd for internal functions that users
#   shouldn't call directly. Without it, roxygen2 would either create a
#   help page (confusing for users) or warn about missing documentation.
#
# DESIGN PRINCIPLE: PURE LOGIC, NO GGPLOT:
#   None of these helpers import or call ggplot2/ggpp. They take simple
#   R values (numbers, strings) and return simple R values. This makes
#   them fast to test, easy to reason about, and reusable if we add
#   more annotation functions later.
#
# =============================================================================


# -- Color constants -----------------------------------------------------------
#
# WHY THESE SPECIFIC COLORS?
#   Pure red (#FF0000) and pure green (#00FF00) are harsh on screen, hard
#   to read against white backgrounds, and problematic for colorblind users
#   (red-green colorblindness affects ~8% of men).
#
#   We use dark, muted tones instead:
#   - Firebrick (#B22222): a deep red that reads as "negative" without
#     screaming. High contrast against white label backgrounds.
#   - Forest green (#2E7D32): a dark green that pairs well with firebrick.
#     Distinguishable from firebrick even in most forms of colorblindness
#     because the VALUE (lightness) differs, not just the hue.
#   - Grey (#808080): neutral, for zero-change cases. Doesn't carry
#     positive or negative connotation.
#
# COLORBLIND NOTE:
#   These colors are not perfectly colorblind-safe (a truly safe palette
#   would use blue/orange). But dark red vs dark green is far better than
#   pure red vs pure green, and it matches the universal business convention
#   of red = bad, green = good. A future version could add a colorblind
#   mode argument.

COLOR_INCREASE <- "#2E7D32"
COLOR_DECREASE <- "#B22222"
COLOR_FLAT     <- "#808080"


#' Compute the delta between two values
#'
#' @param from_value A single numeric value (the starting point).
#' @param to_value A single numeric value (the ending point).
#' @param format One of "percent", "absolute", or "both".
#'
#' @return A list with three elements:
#'   - `value`: the raw numeric difference (to - from).
#'   - `direction`: one of "up", "down", or "flat".
#'   - `label`: a formatted character string (e.g., "+23.4%").
#'
#' @noRd
compute_delta <- function(from_value, to_value, format) {
  # -- Check for NA values (edge case 6) --
  if (is.na(from_value)) {
    stop("Column value is NA in the `from` row. Cannot compute change.",
         call. = FALSE)
  }
  if (is.na(to_value)) {
    stop("Column value is NA in the `to` row. Cannot compute change.",
         call. = FALSE)
  }

  # -- Raw difference --
  diff_value <- to_value - from_value

  # -- Direction (edge case 4: zero change = "flat") --
  direction <- if (diff_value > 0) {
    "up"
  } else if (diff_value < 0) {
    "down"
  } else {
    "flat"
  }

  # -- Format the label --
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
# These are tiny internal functions called only by compute_delta().
# They handle the sign prefix, rounding, and the zero-from-value edge case.

format_percent <- function(from_value, diff_value, direction) {
  # Edge case 1: percent change from zero is undefined.
  # Warn and fall back to absolute format.
  if (from_value == 0) {
    warning(
      "Cannot compute percent change from zero. ",
      "Falling back to absolute change.",
      call. = FALSE
    )
    return(format_absolute(diff_value, direction))
  }

  pct <- (diff_value / from_value) * 100
  sign_prefix <- switch(direction,
    "up"   = "+",
    "down" = "",
    "flat" = ""
  )
  paste0(sign_prefix, format_number(pct, 1), "%")
}


format_absolute <- function(diff_value, direction) {
  sign_prefix <- switch(direction,
    "up"   = "+",
    "down" = "",
    "flat" = ""
  )
  paste0(sign_prefix, format_number(diff_value, 0))
}


format_points <- function(diff_value, direction) {
  sign_prefix <- switch(direction,
    "up"   = "+",
    "down" = "",
    "flat" = ""
  )
  paste0(sign_prefix, format_number(diff_value, 1), " %pts")
}


format_number <- function(x, digits) {
  # Format with fixed decimal places and comma thousands separator.
  # We write our own instead of depending on the scales package.
  # round() first so formatC sees the intended precision.
  formatted <- formatC(
    round(x, digits),
    format = "f",
    digits = digits,
    big.mark = ","
  )
  # formatC pads with spaces by default; trimws cleans that up.
  trimws(formatted)
}


#' Pick a color based on the direction of change
#'
#' @param direction One of "up", "down", or "flat" (as returned by
#'   compute_delta()).
#'
#' @return A color hex string.
#'
#' @noRd
pick_change_color <- function(direction) {
  switch(direction,
    "up"   = COLOR_INCREASE,
    "down" = COLOR_DECREASE,
    "flat" = COLOR_FLAT
  )
}


#' Validate inputs for annotate_change()
#'
#' Checks that data is a data frame, format is valid, and the value
#' column exists and is numeric. Called at the top of annotate_change()
#' before any computation.
#'
#' @param data A data frame.
#' @param value_quo A quosure capturing the value column expression.
#' @param format A character string.
#'
#' @return `invisible(TRUE)` if all checks pass. Throws an error otherwise.
#'
#' @noRd
validate_change_inputs <- function(data, value_quo, format) {
  # -- Check data is a data frame (same pattern as annotate_callout) --
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  # -- Check format is one of the three allowed values --
  valid_formats <- c("percent", "absolute", "points", "both")
  if (!format %in% valid_formats) {
    stop(
      "`format` must be one of: ",
      paste(valid_formats, collapse = ", "), ".",
      call. = FALSE
    )
  }

  # -- Check the value column exists and is numeric --
  # rlang::as_name() converts the quosure to a plain column name string.
  # For example, if the user wrote value = revenue, this gives us "revenue".
  value_name <- rlang::as_name(value_quo)

  if (!value_name %in% names(data)) {
    stop(
      "Column `", value_name, "` not found in `data`.",
      call. = FALSE
    )
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
