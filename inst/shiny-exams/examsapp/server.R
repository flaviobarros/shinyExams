## server.R ##
library(shiny)
library(exams)

shinyServer(function(input, output, session)
{
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
          exname <- if(is.null(input$exname)) paste("shinyEx", input$exmarkup, sep = ".") else input$exname
          exname <- gsub("/", "_", exname, fixed = TRUE)
          writeLines(excode, file.path("tmp", exname))
          ex <- try(exams2html(exname, n = 1, name = "preview", dir = "tmp", edir = "tmp",
                               base64 = c("bmp", "gif", "jpeg", "jpg", "png", "csv", "raw", "txt", "rda", "dta", "xls", "xlsx", "zip", "pdf", "doc", "docx"),
                               encoding = input$exencoding), silent = TRUE)
          if(!inherits(ex, "try-error")) {
            hf <- "preview1.html"
            html <- readLines(file.path("tmp", hf))
            n <- c(which(html == "<body>"), length(html))
            html <- c(
              html[1L:n[1L]],                  ## header
              '<div style="border: 1px solid black;border-radius:5px;padding:8px;">', ## border
              html[(n[1L] + 5L):(n[2L] - 6L)], ## exercise body (omitting <h2> and <ol>)
              '</div>', '</br>',               ## border
              html[(n[2L] - 1L):(n[2L])]       ## footer
            )
            writeLines(html, file.path("tmp", hf))
            return(includeHTML(file.path("tmp", hf)))
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

  foo <- function(x) {
    for(i in seq_along(x))
      cat(x[i], "\n")
    invisible(NULL)
  }

  output$show_exercises <- renderPrint({
    foo(available_exercises())
  })

  output$download_exercises <- downloadHandler(
    filename = function() {
      paste("exercises", "zip", sep = ".")
    },
    content = function(file) {
      owd <- getwd()
      dir.create(tdir <- tempfile())
      file.copy(file.path("exercises", list.files("exercises")), tdir, recursive = TRUE)
      setwd(tdir)
      zip(zipfile = paste("exercises", "zip", sep = "."), files = list.files(tdir))
      setwd(owd)
      file.copy(file.path(tdir, paste("exercises", "zip", sep = ".")), file)
      unlink(tdir)
    }
  )

  output$download_project <- downloadHandler(
    filename = function() {
      paste("exams_project", "zip", sep = ".")
    },
    content = function(file) {
      owd <- getwd()
      dir.create(tdir <- tempfile())
      file.copy(file.path(".", list.files(".")), tdir, recursive = TRUE)
      setwd(tdir)
      zip(zipfile = paste("exams_project", "zip", sep = "."), files = c("exercises", "exams"))
      setwd(owd)
      file.copy(file.path(tdir, paste("exams_project", "zip", sep = ".")), file)
      unlink(tdir)
    }
  )

  final_exam <- reactive({
    input$save_exam
    if(length(list.files("exam"))) {
      exname <- paste(input$exam_name, "rda", sep = ".")
      load(exname)
      return(eval(parse(text = exname)))
    } else return(NULL)
  })
  output$exercises4exam <- renderUI({
    if(!is.null(ex <- final_exam())) {
      ex
    } else {
      input$exam_name
    }
  })
  observeEvent(input$save_exam, {

  })

  observeEvent(input$compile, {
    if(length(input$mychooser$right)) {
      unlink(dir("exams", full.names = TRUE))
      ex <- NULL
      if(input$format == "PDF") {
        ex <- exams2pdf(input$mychooser$right, n = input$n,
                        dir = "exams", edir = "exercises", name = input$name)
      }
      if(input$format == "HTML") {
        ex <- exams2html(input$mychooser$right, n = input$n,
                         dir = "exams", edir = "exercises", name = input$name)
      }
      if(input$format == "QTI12") {
        ex <- exams2qti12(input$mychooser$right, n = input$n,
                          dir = "exams", edir = "exercises", name = input$name)
      }
      if(!is.null(ex))
        save(ex, file = file.path("exams", paste(input$name, "rda", sep = ".")))
    } else return(NULL)
  })
  dlinks <- eventReactive(input$compile, {
    dir("exams", full.names = TRUE)
  })
  output$exams <- renderText({
    basename(dlinks())
  })
  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$name, "zip", sep = ".")
    },
    content = function(file) {
      owd <- getwd()
      setwd(file.path(owd, "exams"))
      zip(zipfile = paste(input$name, "zip", sep = "."), files = list.files(file.path(owd, "exams")))
      setwd(owd)
      file.copy(file.path("exams", paste(input$name, "zip", sep = ".")), file)
    }
  )
})
