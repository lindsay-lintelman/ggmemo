# =============================================================================
# test-placeholder.R — A starter test file for ggmemo
# =============================================================================
#
# HOW TESTTHAT WORKS:
#
# testthat is R's most popular unit testing framework. Here's the anatomy:
#
# 1. TEST FILES live in tests/testthat/ and MUST start with "test-".
#    testthat auto-discovers them by that prefix — no registration needed.
#    Convention: name them after the source file they test, e.g.
#    test-annotate-callout.R tests R/annotate-callout.R.
#
# 2. test_that("description", { ... }) defines one test. The description
#    should read like a sentence: "annotate_callout adds an arrow layer".
#    Inside the braces, you write expectations.
#
# 3. EXPECTATIONS are the assertions. Common ones:
#    - expect_equal(x, y)     — are x and y the same value?
#    - expect_true(x)         — is x TRUE?
#    - expect_error(f(), "msg") — does f() throw an error matching "msg"?
#    - expect_s3_class(x, "gg") — is x a ggplot object?
#    - expect_snapshot(x)     — does x's output match a saved snapshot?
#
# 4. RUNNING TESTS:
#    - devtools::test()          — runs all tests interactively
#    - devtools::test_active_file() — runs just the current file in RStudio
#    - R CMD check (or devtools::check()) — runs tests as part of the
#      full package check, which is what CI does
#
# 5. STYLE: testthat supports two styles:
#    - test_that() blocks (what we use — standard in most R packages)
#    - describe()/it() blocks (BDD-style, borrowed from RSpec/Mocha)
#    Both work fine; test_that() is more common in the R ecosystem.
#
# =============================================================================

test_that("placeholder test passes", {
  # This trivially-passing test exists so that devtools::check() doesn't
  # warn about an empty test suite. We'll replace it with real tests in
  # Week 2 when we write annotate_callout() and annotate_change().
  expect_true(TRUE)
})

# =============================================================================
# ABOUT VDIFFR — Visual regression testing for ggplot2
# =============================================================================
#
# vdiffr is a testthat extension that catches *visual* regressions in plots.
# Instead of checking data values, it renders your plot to an SVG and compares
# it pixel-by-pixel against a saved reference ("snapshot").
#
# Why we'll use it in ggmemo:
#   Our package produces ggplot2 layers with arrows, labels, and formatting.
#   A regular unit test can check that the right geom was added, but can't
#   catch if the arrow points the wrong way or the label overlaps the data.
#   vdiffr catches those visual regressions.
#
# How it works:
#   1. Write a test:
#        vdiffr::expect_doppelganger("my-plot-title", my_plot_object)
#
#   2. First run: vdiffr saves a reference SVG in tests/testthat/_snaps/.
#
#   3. Later runs: it re-renders and compares. If the plot changed, the test
#      fails and you can review the diff with:
#        vdiffr::manage_cases()   (opens a Shiny app showing visual diffs)
#
#   4. To accept an intentional visual change, delete the old snapshot and
#      re-run the test, or use manage_cases() to accept interactively.
#
# We'll add vdiffr tests in Week 2 alongside our annotation functions.
# =============================================================================
