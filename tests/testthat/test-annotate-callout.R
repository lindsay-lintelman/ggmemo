economics <- ggplot2::economics

# -- Return type ---------------------------------------------------------------

test_that("annotate_callout returns a ggplot2 layer", {
  layer <- annotate_callout(
    economics,
    where = date == as.Date("2009-10-01"),
    label = "test"
  )
  expect_s3_class(layer, "LayerInstance")
})


# -- Input validation ----------------------------------------------------------

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


# -- Visual snapshots ----------------------------------------------------------

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
