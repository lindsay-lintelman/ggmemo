# CLAUDE.md — Session context for ggmemo

ggmemo is an R package that adds callout and change annotations to
ggplot2 business charts. Two exported functions: `annotate_callout()`
and `annotate_change()`. Built on ggpp, uses tidy eval for row
selection, no dplyr dependency. Target audience: business analysts
making reports and presentations with ggplot2. The repo is currently
private.

## Required reading

These files contain binding design decisions and project context.
Read them before making changes:

- `inst/notes/DESIGN.md` — design decisions, known limitations
- `inst/notes/v0.2-prompt.md` — detailed plan for the next release
- `NEWS.md` — what's shipped
- `README.md` — user-facing pitch and examples

## Working agreements

### Code style
- Use `ggplot2::` and `ggpp::` namespace prefixes in package code.
  No `@importFrom` except `rlang::.env`.
- One exported function per `R/annotate-*.R` file. Shared internal
  helpers go in `R/utils.R` (general) or `R/utils-change.R`
  (change-specific).
- Error messages: `stop(..., call. = FALSE)`, clear and actionable,
  with fix suggestions for common user mistakes.
- No comments explaining WHAT the code does. Only comment the WHY
  when it's non-obvious.
- Factor x-axes in examples: always specify `levels` to avoid
  alphabetical sorting.

### Development workflow
- Use `devtools::` and `usethis::` for package development tasks.
- Run `devtools::check()` after every change — target zero errors,
  zero warnings.
- Don't add dependencies without asking.
- Write code when asked. For design decisions, propose options and
  let me choose.
- Defer unrelated ideas to GitHub issues rather than expanding the
  current task.

### Git conventions
- Small, descriptive commits (one logical change per commit).
- End commit messages with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Never amend published commits.
- Reference issue numbers with `Closes #N` when work completes an
  issue.

### Testing
- `test-X.R` corresponds to `R/X.R`.
- Use vdiffr snapshots for visual output tests.
- Run `testthat::snapshot_accept("test-name")` after intentional
  visual changes.
- Test pure logic helpers separately from plotting (faster,
  more diagnostic).

## Issue workflow

- If I have an idea unrelated to the current task, I'll say "open
  an issue about X." Capture it via `gh issue create` with
  appropriate labels, then return to the current task.
- If I give you a GitHub issue URL and say "work on this," fetch the
  issue body (`gh issue view <number>`), confirm scope with me,
  then proceed.
- When closing work tied to an issue, reference the issue number in
  the commit message (`Closes #12`).

## Project layout

```
R/                      Package source
  annotate-callout.R      annotate_callout()
  annotate-change.R       annotate_change()
  utils.R                 Shared helpers (filter, nudge, detect x col)
  utils-change.R          Change-specific helpers (delta, format, validate)
  ggmemo-package.R        Package-level docs
tests/testthat/         Unit tests and vdiffr snapshots
vignettes/              "Narrating Business Charts with ggmemo"
inst/notes/             Design docs, code walkthrough, v0.2 prompt
man/                    Generated .Rd help files (don't edit directly)
.github/workflows/      R-CMD-check, test-coverage, pkgdown
```

## Commands

```r
devtools::check()          # Full R CMD check
devtools::test()           # Run testthat suite
devtools::document()       # Regenerate NAMESPACE and .Rd from roxygen
devtools::build_readme()   # Knit README.Rmd -> README.md
pkgdown::build_site()      # Build pkgdown site locally in docs/
```
