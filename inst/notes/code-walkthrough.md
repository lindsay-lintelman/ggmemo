# Code walkthrough — educational notes from Weeks 2-3

These notes were originally inline comments in the R source files.
Moved here during the v0.1.0 polish phase to keep the source lean
while preserving the learning material for reference.

## File naming convention

Tidyverse style uses kebab-case for R source files: `annotate-callout.R`,
not `annotateCallout.R` or `annotate_callout.R`. The function NAME inside
uses snake_case (`annotate_callout`), but the filename uses kebab-case.
This is a convention, not a requirement — R doesn't care about filenames.

## Why `ggplot2::` and `ggpp::` prefixes?

Inside a package, you must refer to functions from other packages using
the explicit namespace prefix: `ggplot2::aes()`, `ggpp::geom_label_s()`, etc.
This is different from interactive R, where `library(ggplot2)` lets you
call `aes()` directly. In package code, `library()` is forbidden — it would
change the user's search path as a side effect. The `::` operator tells R
exactly where to find each function, with no side effects.

You CAN avoid `::` by adding `@importFrom` tags (e.g., `@importFrom ggplot2 aes`),
which register the import in NAMESPACE. But `::` is more explicit and
easier to read — you always know where a function comes from. The
tidyverse style guide recommends `::` for most cases, reserving `@importFrom`
for operators and very frequently used functions.

## What `@export` does

The `@export` tag tells roxygen2 to add this function to the NAMESPACE file,
making it available to users who load your package with `library(ggmemo)`.
Without `@export`, the function would be "internal" — callable within
the package but invisible to users.

## What `@noRd` does

Normally, roxygen2 generates a `.Rd` help file for every documented
function. `@noRd` ("no Rd") suppresses that — the function gets roxygen
comments in the source (useful for developers reading the code) but
no user-facing help page. Use `@noRd` for internal functions that users
shouldn't call directly.

## Why `@examples` matter

R CMD check actually RUNS your `@examples` as a test. If they error, the
check fails. This means examples serve double duty: they're documentation
for the user AND a basic integration test. Every exported function should
have at least one working example.

## Tidy evaluation (NSE) — row selection

The user writes: `where = date == as.Date("2009-10-01")`

R normally would try to evaluate that expression immediately, which
would fail because `date` isn't a variable in the calling environment.
Instead, we CAPTURE the expression unevaluated, then evaluate it later
against the data frame — where `date` IS a column.

`rlang::enquo(where)` captures the user's expression as a "quosure" —
a frozen expression plus the environment it came from.

`rlang::eval_tidy(where_quo, data)` evaluates the quosure against
the data frame columns.

This two-step capture-then-inject pattern is called Non-Standard
Evaluation (NSE). It's the same mechanism behind `dplyr::filter()`
and `ggplot2::aes()`.

## Why `call. = FALSE` in `stop()`

By default, `stop()` includes the function call in the error message,
like: `Error in annotate_callout(...): ...`. That's noisy and often
confusing for users. `call. = FALSE` suppresses it, giving a cleaner
message: `Error: \`data\` must be a data frame.`

## Why `utils-change.R` is a separate file

The tidyverse convention is to put internal helpers in `utils-*.R` files,
named after the feature they support. This keeps `annotate-change.R`
focused on ggplot2 plumbing while the pure business logic lives here.
It also makes these helpers easy to test in isolation.

**Design principle: pure logic, no ggplot.** None of the helpers import
or call ggplot2/ggpp. They take simple R values and return simple R values.
This makes them fast to test, easy to reason about, and reusable.

## Color choices

Pure red (#FF0000) and pure green (#00FF00) are harsh on screen, hard
to read against white backgrounds, and problematic for colorblind users
(red-green colorblindness affects ~8% of men).

We use dark, muted tones instead:
- **Firebrick (#B22222)**: a deep red that reads as "negative" without
  screaming. High contrast against white label backgrounds.
- **Forest green (#2E7D32)**: a dark green that pairs well with firebrick.
  Distinguishable from firebrick even in most forms of colorblindness
  because the VALUE (lightness) differs, not just the hue.
- **Grey (#808080)**: neutral, for zero-change cases.

These colors are not perfectly colorblind-safe (a truly safe palette
would use blue/orange). But dark red vs dark green is far better than
pure red vs pure green, and it matches the business convention of
red = bad, green = good.

## Why `annotate_change()` returns a list of layers

`annotate_callout()` returns a single `ggpp::geom_label_s()` layer, which
handles both the arrow and the label internally. `annotate_change()`
needs a segment (arrow between two points) and a label (at the midpoint),
which are two separate geoms. ggplot2's `+` operator handles lists
transparently: `p + list(geom_segment(...), geom_label(...))` works
exactly like adding them individually.

## The `.env$` pronoun in `aes()`

In `ggplot2::aes(label = .env$label)`, the `.env$` prefix tells ggplot2
"look in the function's environment for a variable called `label`" —
NOT in the data frame. Without `.env$`, ggplot2 would look for a column
named "label" in the data.

## Testing internal helpers

Even though users can't call `compute_delta()` or `pick_change_color()`
directly, testing them separately has big advantages:

1. **Speed**: these tests run in milliseconds — no ggplot rendering.
2. **Diagnostics**: if a helper test fails, you know exactly which piece
   of logic broke. A failing visual test only tells you "the plot
   looks different."
3. **Coverage**: you can test edge cases (NA values, zero denominators)
   that are hard to trigger through the public API alone.

Convention: `test-X.R` corresponds to `R/X.R`.
