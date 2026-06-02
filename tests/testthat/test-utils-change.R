default_colors <- c(up = "#2E7D32", down = "#B22222", flat = "#808080")

# -- compute_delta: direction --------------------------------------------------

test_that("compute_delta detects 'up' direction", {
  result <- compute_delta(100, 150, "percent")
  expect_equal(result$direction, "up")
})

test_that("compute_delta detects 'down' direction", {
  result <- compute_delta(150, 100, "percent")
  expect_equal(result$direction, "down")
})

test_that("compute_delta detects 'flat' direction", {
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


# -- compute_delta: edge cases -------------------------------------------------

test_that("compute_delta warns and falls back when from is zero", {
  expect_warning(
    result <- compute_delta(0, 50, "percent"),
    "Cannot compute percent change from zero"
  )
  expect_equal(result$label, "+50")
  expect_equal(result$direction, "up")
})

test_that("compute_delta handles zero from with absolute format (no warning)", {
  result <- compute_delta(0, 50, "absolute")
  expect_equal(result$label, "+50")
})

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
  expect_invisible(validate_change_inputs(df, value_quo, "percent", default_colors))
})

test_that("validate_change_inputs errors on non-data-frame", {
  value_quo <- rlang::quo(y)
  expect_error(
    validate_change_inputs("not a df", value_quo, "percent", default_colors),
    "must be a data frame"
  )
})

test_that("validate_change_inputs errors on invalid format", {
  df <- data.frame(y = 1:3)
  value_quo <- rlang::quo(y)
  expect_error(
    validate_change_inputs(df, value_quo, "dollars", default_colors),
    "must be one of"
  )
})

test_that("validate_change_inputs errors on missing column", {
  df <- data.frame(x = 1:3)
  value_quo <- rlang::quo(revenue)
  expect_error(
    validate_change_inputs(df, value_quo, "percent", default_colors),
    "not found"
  )
})

test_that("validate_change_inputs errors on non-numeric column", {
  df <- data.frame(name = c("a", "b"))
  value_quo <- rlang::quo(name)
  expect_error(
    validate_change_inputs(df, value_quo, "percent", default_colors),
    "must be numeric"
  )
})

test_that("validate_change_inputs errors on invalid colors", {
  df <- data.frame(y = 1:3)
  value_quo <- rlang::quo(y)
  expect_error(
    validate_change_inputs(df, value_quo, "percent", c("red", "green")),
    "named character vector"
  )
})
