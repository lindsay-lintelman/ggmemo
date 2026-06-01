# =============================================================================
# test-utils-change.R — Tests for the internal helpers in R/utils-change.R
# =============================================================================
#
# WHY TEST INTERNAL (UNEXPORTED) HELPERS?
#   Even though users can't call compute_delta() or pick_change_color()
#   directly, testing them separately has big advantages:
#
#   1. SPEED: these tests run in milliseconds — no ggplot rendering.
#   2. DIAGNOSTICS: if a helper test fails, you know exactly which piece
#      of logic broke. A failing visual test only tells you "the plot
#      looks different" — you'd have to dig to find the root cause.
#   3. COVERAGE: you can test edge cases (NA values, zero denominators)
#      that are hard to trigger through the public API alone.
#
#   testthat can access internal functions because devtools::test() loads
#   the package with devtools::load_all(), which exposes unexported
#   functions to the test environment. In R CMD check, the tests/testthat.R
#   file calls library(ggmemo) + test_check(), which also makes internals
#   accessible within the package's test suite.
#
# NAMING: test-utils-change.R matches R/utils-change.R, following the
#   convention that test-X.R tests R/X.R.
# =============================================================================


# -- pick_change_color ---------------------------------------------------------

test_that("pick_change_color returns green for 'up'", {
  expect_equal(pick_change_color("up"), "#2E7D32")
})

test_that("pick_change_color returns red for 'down'", {
  expect_equal(pick_change_color("down"), "#B22222")
})

test_that("pick_change_color returns grey for 'flat'", {
  expect_equal(pick_change_color("flat"), "#808080")
})


# -- compute_delta: direction --------------------------------------------------

test_that("compute_delta detects 'up' direction", {
  result <- compute_delta(100, 150, "percent")
  expect_equal(result$direction, "up")
})

test_that("compute_delta detects 'down' direction", {
  result <- compute_delta(150, 100, "percent")
  expect_equal(result$direction, "down")
})

test_that("compute_delta detects 'flat' direction (edge case 4)", {
  result <- compute_delta(100, 100, "percent")
  expect_equal(result$direction, "flat")
  expect_equal(result$label, "0.0%")
})


# -- compute_delta: percent format ---------------------------------------------

test_that("compute_delta formats percent with sign and one decimal", {
  result <- compute_delta(100, 123.456, "percent")
  expect_equal(result$label, "+23.5%")
})

test_that("compute_delta formats negative percent", {
  result <- compute_delta(200, 170, "percent")
  expect_equal(result$label, "-15.0%")
})


# -- compute_delta: absolute format --------------------------------------------

test_that("compute_delta formats absolute with sign", {
  result <- compute_delta(100, 150, "absolute")
  expect_equal(result$label, "+50")
})

test_that("compute_delta formats large absolute with commas", {
  result <- compute_delta(1000, 13500, "absolute")
  expect_equal(result$label, "+12,500")
})

test_that("compute_delta formats negative absolute", {
  result <- compute_delta(150, 100, "absolute")
  expect_equal(result$label, "-50")
})


# -- compute_delta: points format ----------------------------------------------

test_that("compute_delta 'points' format shows difference with %pts suffix", {
  result <- compute_delta(2.2, 12.0, "points")
  expect_equal(result$label, "+9.8 %pts")
})

test_that("compute_delta 'points' format handles decrease", {
  result <- compute_delta(12.0, 2.2, "points")
  expect_equal(result$label, "-9.8 %pts")
})

test_that("compute_delta 'points' format handles zero change", {
  result <- compute_delta(5.0, 5.0, "points")
  expect_equal(result$label, "0.0 %pts")
})


# -- compute_delta: both format ------------------------------------------------

test_that("compute_delta 'both' format shows percent and absolute", {
  result <- compute_delta(100, 150, "both")
  expect_equal(result$label, "+50.0%\n(+50)")
})


# -- compute_delta: edge case 1 (from is zero) --------------------------------

test_that("compute_delta warns and falls back when from is zero", {
  expect_warning(
    result <- compute_delta(0, 50, "percent"),
    "Cannot compute percent change from zero"
  )
  # Falls back to absolute format
  expect_equal(result$label, "+50")
  expect_equal(result$direction, "up")
})

test_that("compute_delta handles zero from with absolute format (no warning)", {
  result <- compute_delta(0, 50, "absolute")
  expect_equal(result$label, "+50")
})


# -- compute_delta: edge case 6 (NA values) -----------------------------------

test_that("compute_delta errors on NA from_value", {
  expect_error(
    compute_delta(NA, 100, "percent"),
    "NA in the `from` row"
  )
})

test_that("compute_delta errors on NA to_value", {
  expect_error(
    compute_delta(100, NA, "percent"),
    "NA in the `to` row"
  )
})


# -- validate_change_inputs ----------------------------------------------------

test_that("validate_change_inputs passes on valid inputs", {
  df <- data.frame(x = 1:3, y = c(10, 20, 30))
  value_quo <- rlang::quo(y)
  expect_invisible(validate_change_inputs(df, value_quo, "percent"))
})

test_that("validate_change_inputs errors on non-data-frame", {
  value_quo <- rlang::quo(y)
  expect_error(
    validate_change_inputs("not a df", value_quo, "percent"),
    "must be a data frame"
  )
})

test_that("validate_change_inputs errors on invalid format", {
  df <- data.frame(y = 1:3)
  value_quo <- rlang::quo(y)
  expect_error(
    validate_change_inputs(df, value_quo, "dollars"),
    "must be one of"
  )
})

test_that("validate_change_inputs errors on missing column", {
  df <- data.frame(x = 1:3)
  value_quo <- rlang::quo(revenue)
  expect_error(
    validate_change_inputs(df, value_quo, "percent"),
    "not found"
  )
})

test_that("validate_change_inputs errors on non-numeric column", {
  df <- data.frame(name = c("a", "b"))
  value_quo <- rlang::quo(name)
  expect_error(
    validate_change_inputs(df, value_quo, "percent"),
    "must be numeric"
  )
})
