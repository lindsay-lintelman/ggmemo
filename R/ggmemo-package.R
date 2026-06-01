# =============================================================================
# ggmemo-package.R — Package-level documentation
# =============================================================================
#
# WHAT THIS FILE DOES:
#
# This file serves two purposes in an R package:
#
# 1. PACKAGE HELP PAGE: The special string "_PACKAGE" below tells roxygen2
#    to generate the help page you see when a user types ?ggmemo or
#    help(package = "ggmemo"). roxygen2 auto-populates it from the Title
#    and Description fields in DESCRIPTION — you don't duplicate that text.
#
# 2. NAMESPACE DECLARATIONS: The "usethis namespace" comments below are
#    markers where usethis::use_import_from() inserts @importFrom tags.
#    For example, if you later run:
#      usethis::use_import_from("ggplot2", "ggplot")
#    it adds a line between those markers, and roxygen2 picks it up to
#    write the NAMESPACE file.
#
# WHY @keywords internal?
#   This keeps the "_PACKAGE" page out of the pkgdown function reference
#   index. Users can still find it via ?ggmemo, but it won't clutter the
#   alphabetical function listing alongside your real functions.
#
# WHY NULL AT THE BOTTOM?
#   roxygen2 needs an R object to attach documentation to. NULL is the
#   conventional placeholder — it doesn't create anything in the package,
#   it just gives roxygen2 something to hang the docs on.
#
# =============================================================================

#' @description
#' ggmemo provides two annotation functions for ggplot2 business charts:
#'
#' - [annotate_callout()]: Point at a specific data row with an arrow and
#'   label (e.g., "Peak unemployment" or "All-time low: 2.2%").
#' - [annotate_change()]: Draw a color-coded arrow between two data rows
#'   and label the delta as percent change, absolute change, or percentage
#'   points (e.g., "+31.7%", "+26", "+9.8 %pts").
#'
#' Both functions use tidy evaluation for row selection, auto-compute
#' coordinates from the data, and return standard ggplot2 layers that
#' you add with `+`.
#'
#' @section When to use ggmemo:
#' Use ggmemo when you want to annotate a ggplot2 chart with arrows,
#' callout labels, or change annotations without manually computing
#' coordinates, formatting deltas, or positioning text. Common
#' scenarios: quarterly reports, executive dashboards, time-series
#' narration, before/after comparisons.
#'
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .env
## usethis namespace: end
NULL
