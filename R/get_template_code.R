#' Get Templates
#'
#' Get templates to show in the editor viewer
#'
#' @param type Options: schoice, num, mchoice, string, cloze
#' @param markup Can be Latex or Rmarkdown
#'
#' @return The templates of schoice, num, mchoice, string or cloze exercises
#' @export
#'
#' @examples
#' get_template_code('mchoice', 'LaTeX')
#' @keywords internal
get_template_code <- function(type, markup = 'LaTeX') {
  if(markup == "LaTeX") {
    excode <- switch(type,
                     "schoice" = readLines(system.file("templates", "schoice.Rnw", package = "shinyExams", mustWork = TRUE)),
                     "num" = readLines(system.file("templates", "num.Rnw", package = "shinyExams", mustWork = TRUE)),
                     "mchoice" = readLines(system.file("templates", "mchoice.Rnw", package = "shinyExams", mustWork = TRUE)),
                     "string" = readLines(system.file("templates", "string.Rnw", package = "shinyExams", mustWork = TRUE)),
                     "cloze" = readLines(system.file("templates", "cloze.Rnw", package = "shinyExams", mustWork = TRUE))
    )
  } else {
    excode <- switch(type,
                     "schoice" = readLines(system.file("templates", "schoice.Rmd", package = "shinyExams", mustWork = TRUE)),
                     "num" = readLines(system.file("templates", "num.Rmd", package = "shinyExams", mustWork = TRUE)),
                     "mchoice" = readLines(system.file("templates", "mchoice.Rmd", package = "shinyExams", mustWork = TRUE)),
                     "string" = readLines(system.file("templates", "string.Rmd", package = "shinyExams", mustWork = TRUE)),
                     "cloze" = readLines(system.file("templates", "cloze.Rmd", package = "shinyExams", mustWork = TRUE))
    )
  }

  return(excode)
}
