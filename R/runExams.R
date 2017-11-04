#' @export
runExample <- function() {
  appDir <- system.file("shiny-exams", "examsapp", package = "shinyExams")
  if (appDir == "") {
    stop("Could not find app directory. Try re-installing `shinyExams`.", call. = FALSE)
  }

  shiny::runApp(appDir, display.mode = "normal")
}
