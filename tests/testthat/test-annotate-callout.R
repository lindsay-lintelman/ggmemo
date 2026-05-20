# =============================================================================
# test-annotate-callout.R — Tests for annotate_callout()
# =============================================================================
#
# TEST ORGANIZATION:
#   Each test_that() block tests ONE specific behavior. The description string
#   should read as a sentence: "annotate_callout returns a ggplot2 layer."
#   If a test has too many expectations, it's probably testing too many things
#   and should be split.
#
# NAMING CONVENTION:
#   This file is named test-annotate-callout.R to match R/annotate-callout.R.
#   testthat auto-discovers files starting with "test-" in this directory.
#
# RUNNING TESTS:
#   devtools::test()               — runs ALL test files
#   devtools::test_active_file()   — runs just this file (in RStudio)
#   testthat::test_file("tests/testthat/test-annotate-callout.R")  — same
#   devtools::check()              — runs tests as part of full R CMD check
#
# SNAPSHOT TESTS (vdiffr):
#   On first run, vdiffr saves reference SVGs in tests/testthat/_snaps/.
#   On later runs, it compares new renders against references.
#   If a test "fails" because no baseline exists yet, run:
#     testthat::snapshot_accept("annotate-callout")
#   to accept the new baselines. The argument is the test file name without
#   the "test-" prefix and ".R" suffix.
#
# WHY ggplot2::economics INSTEAD OF JUST economics?
#   In interactive R, library(ggplot2) makes economics available. But in
#   tests, only your package is loaded (via tests/testthat.R). Datasets
#   from other packages aren't automatically available — you need the
#   full ggplot2::economics path, just like you'd use ggplot2::ggplot().
# =============================================================================

economics <- ggplot2::economics

# -- Return type ---------------------------------------------------------------
# The most basic contract: does this function return the right kind of object?
# ggplot2 layers have class "LayerInstance" — that's what geom_point(),
# geom_line(), etc. all return. Our function should too, so it works with +.

test_that("annotate_callout returns a ggplot2 layer", {
  layer <- annotate_callout(
    economics,
    where = date == as.Date("2009-10-01"),
    label = "test"
  )
  expect_s3_class(layer, "LayerInstance")
})


# -- Input validation: zero rows -----------------------------------------------
# If the where expression matches nothing, the user made a mistake (typo in
# the filter, wrong date, etc.). We should fail fast with a helpful message.

test_that("annotate_callout errors when where matches zero rows", {
  expect_error(
    annotate_callout(
      economics,
      where = date == as.Date("1800-01-01"),
      label = "nothing here"
    ),
    "matched no rows"
  )
})


# -- Input validation: multiple rows -------------------------------------------
# If where matches 2+ rows, the callout can't know which point to annotate.
# This is also a user mistake — their filter wasn't specific enough.

test_that("annotate_callout errors when where matches multiple rows", {
  expect_error(
    annotate_callout(
      economics,
      where = unemploy > 10000,
      label = "too many"
    ),
    "must match exactly one"
  )
})


# -- Visual snapshot: top-right (default) position -----------------------------
# vdiffr::expect_doppelganger() renders the plot to SVG and compares against
# a saved reference. The first argument is a human-readable name that becomes
# the snapshot filename. The second is a ggplot object (not a layer — a
# complete plot with data, geoms, and our annotation).

test_that("annotate_callout renders correctly at top-right", {
  p <- ggplot2::ggplot(economics, ggplot2::aes(x = date, y = unemploy)) +
    ggplot2::geom_line() +
    annotate_callout(
      economics,
      where = date == as.Date("2000-01-01"),
      label = "Y2K low",
      position = "top-right"
    )
  vdiffr::expect_doppelganger("callout-top-right", p)
})


# -- Visual snapshot: bottom-left position -------------------------------------
# Tests the opposite corner to make sure our sign logic works and the arrow
# points in the right direction.

test_that("annotate_callout renders correctly at bottom-left", {
  p <- ggplot2::ggplot(economics, ggplot2::aes(x = date, y = unemploy)) +
    ggplot2::geom_line() +
    annotate_callout(
      economics,
      where = date == as.Date("2009-10-01"),
      label = "Peak unemployment",
      position = "bottom-left"
    )
  vdiffr::expect_doppelganger("callout-bottom-left", p)
})
