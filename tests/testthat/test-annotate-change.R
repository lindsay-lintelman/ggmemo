revenue <- data.frame(
  quarter = factor(c("Q1", "Q2", "Q3", "Q4"),
                   levels = c("Q1", "Q2", "Q3", "Q4")),
  revenue = c(120, 145, 132, 158)
)

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
  expect_length(layers, 4)
  expect_s3_class(layers[[1]], "LayerInstance")
  expect_s3_class(layers[[2]], "LayerInstance")
  expect_s3_class(layers[[3]], "CoordCartesian")
  expect_s3_class(layers[[4]], "ScaleContinuous")
})


# -- Input validation ----------------------------------------------------------

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

test_that("annotate_change errors on character x-axis with helpful message", {
  char_data <- data.frame(
    quarter = c("Q1", "Q2"),
    revenue = c(100, 150)
  )
  expect_error(
    annotate_change(char_data, from = quarter == "Q1", to = quarter == "Q2",
                    value = revenue),
    "character vector.*preserve data order"
  )
})

test_that("annotate_change suggests as.Date for date-like character columns", {
  date_data <- data.frame(
    date = c("2024-01-15", "2024-03-15"),
    revenue = c(100, 200)
  )
  expect_error(
    annotate_change(date_data, from = date == "2024-01-15",
                    to = date == "2024-03-15", value = revenue),
    "looks like a date.*as\\.Date"
  )
})

test_that("annotate_change errors with clear message when value is missing", {
  expect_error(
    annotate_change(revenue, from = quarter == "Q1", to = quarter == "Q4"),
    "`value` is required"
  )
})


# -- expand_y behaviour --------------------------------------------------------

test_that("annotate_change omits scale layer when curvature is 0", {
  layers <- annotate_change(
    revenue,
    from = quarter == "Q1",
    to = quarter == "Q4",
    value = revenue,
    curvature = 0
  )
  expect_length(layers, 3)
  classes <- vapply(layers, function(x) class(x)[1], character(1))
  expect_false("ScaleContinuous" %in% classes)
})

test_that("annotate_change omits scale layer when expand_y = FALSE", {
  layers <- annotate_change(
    revenue,
    from = quarter == "Q1",
    to = quarter == "Q4",
    value = revenue,
    expand_y = FALSE
  )
  expect_length(layers, 3)
})


# -- Visual snapshots ----------------------------------------------------------

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
