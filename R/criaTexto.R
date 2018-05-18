#' Insert random text
#'
#' Call this function as an addin to create a file and insert text.
#'
#' @export
criaTexto <- function() {
  if (!file.exists('Teste.Rd')) {
    file.create('Teste.Rd')
  }
  rstudioapi::navigateToFile('Teste.Rd', line = 1, column = 1)
  rstudioapi::getActiveDocumentContext()
  rstudioapi::setDocumentContents('random text')
}
