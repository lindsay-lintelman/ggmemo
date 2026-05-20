
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ggmemo

<!-- badges: start -->

<!-- badges: end -->

ggmemo provides semantic, opinionated annotation helpers for business
charts built with ggplot2. Instead of manually computing deltas,
formatting percentages, and fiddling with arrow coordinates, you call
high-level verbs like `annotate_callout()` and `annotate_change()` that
handle the details for you. Built on top of the
[ggpp](https://docs.r4photobiology.info/ggpp/) package for precise
annotation positioning.

## Installation

You can install the development version of ggmemo from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("lindsay-lintelman/ggmemo")
```

## Example

Here’s a U.S. unemployment time series with a callout pointing at the
Great Recession peak — one line of ggmemo code instead of manual arrow
and label coordinates:

``` r
library(ggplot2)
library(ggmemo)

ggplot(economics, aes(x = date, y = unemploy)) +
  geom_line() +
  annotate_callout(
    economics,
    where = date == as.Date("2009-10-01"),
    label = "Peak unemployment",
    position = "bottom-left"
  ) +
  labs(
    title = "U.S. Unemployment (thousands)",
    x = NULL, y = NULL
  )
```

<img src="man/figures/README-example-1.png" alt="" width="100%" />
