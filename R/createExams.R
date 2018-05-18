#' Insert random text
#'
#' Call this function as an addin to create a file and insert text.
#'
#' @export
#' @import shiny
#' @import shinyAce
#' @import miniUI
#' @import exams
# We'll wrap our Shiny Gadget in an addin.
# Let's call it 'clockAddin()'.
createExams <- function() {

  # Our ui will be a simple gadget page, which
  # simply displays the time in a 'UI' output.
  ui <- miniPage(
    gadgetTitleBar("Create Exercise"),
    miniContentPanel(

      ## Main edition
      fluidRow(
        # column(4,
        #        uiOutput("select_imported_exercise"),
        #        conditionalPanel('input.selected_exercise != ""', uiOutput("show_selected_exercise"))
        # ),
        column(4,
               selectInput("exencoding", label = "Encoding?", choices = c("ASCII", "UTF-8", "Latin-1", "Latin-2", "Latin-3",
                                                                          "Latin-4", "Latin-5", "Latin-6", "Latin-7", "Latin-8", "Latin-9", "Latin-10"),
                           selected = "UTF-8")
        )
      ),
      fluidRow(
        column(9,
               uiOutput("editor", inline = TRUE, container = div),
               uiOutput("player", inline = TRUE, container = div)
        ),
        column(3,
               selectInput("exmarkup", label = "Load a template. Markup?", choices = c("LaTeX", "Markdown"),
                           selected = "LaTeX"),
               selectInput("extype", label = ("Type?"),
                           choices = c("num", "schoice", "mchoice", "string", "cloze"),
                           selected = "num"),
               actionButton("load_editor_template", label = "Load template"),
               uiOutput("playbutton")
               ## Implement import from questions of exams package
               #hr(),
               #selectInput("exams_exercises", label = "Load exams package exercises.",
                #           choices = list.files(file.path(find.package("exams"), "exercises")),
                #           selected = "boxplots.Rnw"),
               #actionButton("load_editor_exercise", label = "Load exercise")
        )
      )#,
      # There is no need to save a file
      # tags$hr(),
      # uiOutput("exnameshow"),
      # actionButton("save_ex", label = "Save exercise"),
      # br(), br()
    )
  )

  server <- function(input, output, session) {

    ## Multiple functions with inputs
    available_exercises <- reactive({
      e1 <- input$save_ex
      e2 <- input$ex_upload
      exfiles <- list.files("exercises", recursive = TRUE)
      if(!is.null(input$selected_exercise)) {
        if(input$selected_exercise != "") {
          if(input$selected_exercise %in% exfiles) {
            i <- which(exfiles == input$selected_exercise)
            exfiles <- c(exfiles[i], exfiles[-i])
          }
        }
      }
      return(exfiles)
    })

    output$select_imported_exercise <- renderUI({
      selectInput('selected_exercise', 'Select exercise to be modified.',
                  available_exercises())
    })

    output$show_selected_exercise <- renderUI({
      if(!is.null(input$selected_exercise)) {
        if(input$selected_exercise != "") {
          excode <- readLines(file.path("exercises", input$selected_exercise))
          output$exnameshow <- renderUI({
            textInput("exname", label = "Exercise name.", value = input$selected_exercise)
          })
          output$editor <- renderUI({
            aceEditor("excode", if(input$exmarkup == "LaTeX") "tex" else "markdown",
                      value = paste(gsub('\\', '\\\\', excode, fixed = TRUE), collapse = '\n'))
          })
        }
        return(NULL)
      } else return(NULL)
    })

    output$editor <- renderUI({
      aceEditor("excode", if(input$exmarkup == "LaTeX") "tex" else "markdown",
                value = "Create/edit exercises here!")
    })

    output$playbutton <- renderUI({
      actionButton("play_exercise", label = "Show preview")
    })

    output$exnameshow <- renderUI({
      textInput("exname", label = "Exercise name.", value = input$exname)
    })

    observeEvent(input$load_editor_template, {
      exname <- paste("template-", input$extype, ".", if(input$exmarkup == "LaTeX") "Rnw" else "Rmd", sep = "")
      excode <- get_template_code(input$extype, input$exmarkup)
      output$exnameshow <- renderUI({
        textInput("exname", label = "Exercise name.", value = exname)
      })
      output$editor <- renderUI({
        aceEditor("excode", mode = if(input$exmarkup == "LaTeX") "tex" else "markdown",
                  value = paste(gsub('\\', '\\\\', excode, fixed = TRUE), collapse = '\n'))
      })
    })

    observeEvent(input$load_editor_exercise, {
      exname <- input$exams_exercises
      expath <- file.path(find.package("exams"), "exercises", exname)
      excode <- readLines(expath)
      output$exnameshow <- renderUI({
        textInput("exname", label = "Exercise name.", value = exname)
      })
      markup <- tolower(file_ext(exname))
      output$editor <- renderUI({
        aceEditor("excode", mode = if(markup == "rnw") "tex" else "markdown",
                  value = paste(gsub('\\', '\\\\', excode, fixed = TRUE), collapse = '\n'))
      })
    })

    observeEvent(input$save_ex, {
      if(input$exname != "") {
        writeLines(input$excode, file.path("exercises", input$exname))
      }
      exfiles <- list.files("exercises", recursive = TRUE)
      session$sendCustomMessage(type = 'exHandler', exfiles)
    })

    observeEvent(input$play_exercise, {
      excode <- input$excode
      output$playbutton <- renderUI({
        actionButton("show_editor", label = "Hide preview")
      })
    })

    observeEvent(input$show_editor, {
      output$playbutton <- renderUI({
        actionButton("play_exercise", label = "Show preview")
      })
    })

    exercise_code <- reactive({
      excode <- input$excode
    })

    output$player <- renderUI({
      if(!is.null(input$play_exercise)) {
        if(input$play_exercise > 0) {
          unlink(dir("tmp", full.names = TRUE, recursive = TRUE))
          excode <- exercise_code()
          if(excode[1] != "Create/edit exercises here!") {
            #exname <- if(is.null(input$exname)) paste("shinyEx", input$exmarkup, sep = ".") else input$exname
            #exname <- gsub("/", "_", exname, fixed = TRUE)
            exname <- tempfile()
            writeLines(excode, exname)
            ex <- try(exams2html(exname, n = 1, name = "preview", dir = tempdir(), edir = tempdir(),
                                 base64 = c("bmp", "gif", "jpeg", "jpg", "png", "csv", "raw", "txt", "rda", "dta", "xls", "xlsx", "zip", "pdf", "doc", "docx"),
                                 encoding = input$exencoding), silent = TRUE)
            if(!inherits(ex, "try-error")) {
              hf <- "preview1.html"
              html <- readLines(file.path(tempdir(), hf))
              n <- c(which(html == "<body>"), length(html))
              html <- c(
                html[1L:n[1L]],                  ## header
                '<div style="border: 1px solid black;border-radius:5px;padding:8px;">', ## border
                html[(n[1L] + 5L):(n[2L] - 6L)], ## exercise body (omitting <h2> and <ol>)
                '</div>', '</br>',               ## border
                html[(n[2L] - 1L):(n[2L])]       ## footer
              )
              writeLines(html, file.path(tempdir(), hf))
              return(includeHTML(file.path(tempdir(), hf)))
            } else {
              return(HTML(paste('<div>', ex, '</div>')))
            }
          } else return(NULL)
        } else return(NULL)
      } else return(NULL)
    })

    observeEvent(input$ex_upload, {
      if(!is.null(input$ex_upload$datapath)) {
        for(i in seq_along(input$ex_upload$name)) {
          fext <- tolower(file_ext(input$ex_upload$name[i]))
          if(fext %in% c("rnw", "rmd")) {
            file.copy(input$ex_upload$datapath[i], file.path("exercises", input$ex_upload$name[i]))
          } else {
            tdir <- tempfile()
            dir.create(tdir)
            owd <- getwd()
            setwd(tdir)
            file.copy(input$ex_upload$datapath[i], input$ex_upload$name[i])
            if(fext == "zip") {
              unzip(input$ex_upload$name[i], exdir = ".")
            } else {
              untar(input$ex_upload$name[i], exdir = ".")
            }
            file.remove(input$ex_upload$name[i])
            cf <- dir(tdir)
            file.copy(cf, file.path(owd, "exercises"), recursive = TRUE)
            setwd(owd)
            unlink(tdir)
          }
        }
        exfiles <- list.files("exercises", recursive = TRUE)
        session$sendCustomMessage(type = 'exHandler', exfiles)
      }
    })

    output$show_exercises <- renderPrint({
      foo(available_exercises())
    })

    # Listen for 'done' events. When we're finished, we'll
    # insert the current time, and then stop the gadget.
    observeEvent(input$done, {
      rstudioapi::getActiveDocumentContext()
      rstudioapi::setDocumentContents(exercise_code())
      stopApp()
    })

  }

  # We'll use a pane viwer, and set the minimum height at
  # 300px to ensure we get enough screen space to display the clock.
  viewer <- paneViewer(300)
  runGadget(ui, server, viewer = viewer)

}
