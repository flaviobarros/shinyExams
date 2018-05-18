#' Insert random text
#'
#' Call this function as an addin to create a file and insert text.
#'
#' @export
criaTexto <- function() {
  file.create('Teste.Rd')
  rstudioapi::navigateToFile('Teste.Rd')
  rstudioapi::setDocumentContents('random text')
}
