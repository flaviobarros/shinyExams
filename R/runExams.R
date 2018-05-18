#' Starts the shiny app
#'
#' Call this function to start the shiny app.
#'
#' @export
createExams <- function() {

  ## Input handler for questions
  shiny::registerInputHandler("shinyjsexamples.chooser", function(data, ...) {
    if(is.null(data))
      NULL
    else
      list(questions=as.character(data$questions), left=as.character(data$left), right=as.character(data$right))
  }, force = TRUE)

  appDir <- system.file("shiny-exams", "examsapp", package = "shinyExams")
  if (appDir == "") {
    stop("Could not find app directory. Try re-installing `shinyExams`.", call. = FALSE)
  }

  shiny::runApp(appDir = appDir, display.mode = "normal")
}
