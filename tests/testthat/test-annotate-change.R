# =============================================================================
# test-annotate-change.R — Tests for annotate_change()
# =============================================================================
#
# HOW THIS FILE RELATES TO test-utils-change.R:
#   test-utils-change.R tests the pure-logic helpers (compute_delta,
#   pick_change_color, validate_change_inputs) in isolation — fast,
#   focused, no ggplot2 rendering needed.
#
#   This file tests the main function as an integration point: does it
#   wire the helpers together correctly and produce valid ggplot2 layers?
#   We keep it lean — one return-type check, one error check, and three
#   visual snapshots — because the helper tests already cover edge cases
#   exhaustively.
#
# WHY WE CHECK FOR A LIST (NOT A SINGLE LAYER):
#   annotate_callout() returns a single ggpp::geom_label_s() layer.
#   annotate_change() returns a LIST of two layers (segment + label),
#   because it needs two separate geoms that ggplot2's + operator handles
#   transparently: p + list(layer1, layer2) works like p + layer1 + layer2.
#   So the return-type test checks for a length-2 list of LayerInstance
#   objects, not a single LayerInstance.
#
# =============================================================================

# -- Shared test data ----------------------------------------------------------
# A small, predictable dataset used across all tests in this file.
# Using a local data frame (not ggplot2::economics) because we need full
# control over the values to test specific directions and the flat case.

revenue <- data.frame(
  quarter = factor(c("Q1", "Q2", "Q3", "Q4"),
                   levels = c("Q1", "Q2", "Q3", "Q4")),
  revenue = c(120, 145, 132, 158)
)

# A dataset with two identical values for the "flat" snapshot.
flat_data <- data.frame(
  quarter = factor(c("Q1", "Q2"), levels = c("Q1", "Q2")),
  revenue = c(100, 100)
)


# -- Return type ---------------------------------------------------------------

test_that("annotate_change returns a list of two ggplot2 layers", {
  layers <- annotate_change(
    revenue,
    from = quarter == "Q1",
    to = quarter == "Q4",
    value = revenue
  )
  expect_type(layers, "list")
  expect_length(layers, 2)
  expect_s3_class(layers[[1]], "LayerInstance")
  expect_s3_class(layers[[2]], "LayerInstance")
})


# -- Input validation (one representative case) --------------------------------
# The helpers are tested exhaustively in test-utils-change.R. Here we just
# confirm that errors propagate correctly through the main function.

test_that("annotate_change errors when from matches zero rows", {
  expect_error(
    annotate_change(
      revenue,
      from = quarter == "Q5",
      to = quarter == "Q4",
      value = revenue
    ),
    "matched no rows"
  )
})


# -- Visual snapshot: increase (green arrow, percent label) --------------------

test_that("annotate_change renders an increase correctly", {
  p <- ggplot2::ggplot(revenue, ggplot2::aes(x = quarter, y = revenue)) +
    ggplot2::geom_col(fill = "grey70", width = 0.6) +
    annotate_change(
      revenue,
      from = quarter == "Q1",
      to = quarter == "Q4",
      value = revenue
    )
  vdiffr::expect_doppelganger("change-increase", p)
})


# -- Visual snapshot: decrease (red arrow, percent label) ----------------------

test_that("annotate_change renders a decrease correctly", {
  p <- ggplot2::ggplot(revenue, ggplot2::aes(x = quarter, y = revenue)) +
    ggplot2::geom_col(fill = "grey70", width = 0.6) +
    annotate_change(
      revenue,
      from = quarter == "Q2",
      to = quarter == "Q3",
      value = revenue
    )
  vdiffr::expect_doppelganger("change-decrease", p)
})


# -- Visual snapshot: flat / zero change (grey arrow, 0.0% label) --------------

test_that("annotate_change renders zero change correctly", {
  p <- ggplot2::ggplot(flat_data, ggplot2::aes(x = quarter, y = revenue)) +
    ggplot2::geom_col(fill = "grey70", width = 0.6) +
    annotate_change(
      flat_data,
      from = quarter == "Q1",
      to = quarter == "Q2",
      value = revenue
    )
  vdiffr::expect_doppelganger("change-flat", p)
})
