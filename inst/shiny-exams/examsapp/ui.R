## ui.R ##
library(shiny)
shinyUI(pageWithSidebar(

  ## Application title.
  headerPanel("shinyExams Editor"),

  NULL,

  ## Show a plot of the generated distribution.
  mainPanel(
    tags$style(HTML("
                    .gray-node {
                    color: #E59400;
                    }
                    ")),
    tags$head(tags$script(
      list(
        ## Getting data from server.
        HTML('Shiny.addCustomMessageHandler("exHandler", function(data) {
             var dest = $("div.chooser-left-container").find("select.left");
             dest.empty();
             if ( typeof(data) == "string" ) {
             dest.append("<option>"+data+"</option>");
             } else {
             $.each(data, function(key, val) {
             dest.append("<option>"+val+"</option>");
             });
             }
             });'))
         )
      ),
    tabsetPanel(
      tabPanel("Create/Edit Exercises",
               br(),
               fluidRow(
                 column(4,
                        uiOutput("select_imported_exercise"),
                        conditionalPanel('input.selected_exercise != ""', uiOutput("show_selected_exercise"))
                 ),
                 column(4,
                        selectInput("exencoding", label = "Encoding?", choices = c("ASCII", "UTF-8", "Latin-1", "Latin-2", "Latin-3",
                                                                                   "Latin-4", "Latin-5", "Latin-6", "Latin-7", "Latin-8", "Latin-9", "Latin-10"),
                                    selected = "UTF-8")
                 )
               ),
               fluidRow(
                 column(9,
                        uiOutput("editor", inline = TRUE, container = div),
                        uiOutput("player", inline = TRUE, container = div),
                        uiOutput("playbutton")
                 ),
                 column(3,
                        selectInput("exmarkup", label = "Load a template. Markup?", choices = c("LaTeX", "Markdown"),
                                    selected = "LaTeX"),
                        selectInput("extype", label = ("Type?"),
                                    choices = c("num", "schoice", "mchoice", "string", "cloze"),
                                    selected = "num"),
                        actionButton("load_editor_template", label = "Load template"),
                        hr(),
                        selectInput("exams_exercises", label = "Load exams package exercises.",
                                    choices = list.files(file.path(find.package("exams"), "exercises")),
                                    selected = "boxplots.Rnw"),
                        actionButton("load_editor_exercise", label = "Load exercise")
                 )
               ),
               tags$hr(),
               uiOutput("exnameshow"),
               actionButton("save_ex", label = "Save exercise"),
               br(), br()
      ),
      tabPanel("Import/Export Exercises",
               br(),
               p("Import exercises in", strong('.Rnw'), ",", strong(".Rmd"),
                 "format, also provided as", strong(".zip"), "or", strong(".tar.gz"), "files!",
                 "Import images in", strong(".jpg"), "and", strong("png"), "format!",
                 "Import an existing project!"),
               fileInput("ex_upload", NULL, multiple = TRUE,
                         accept = c("text/Rnw", "text/Rmd", "text/rnw", "text/rmd", "zip", "tar.gz",
                                    "jpg", "JPG", "png", "PNG")),
               tags$hr(),
               p("List of loaded exercises:"),
               verbatimTextOutput("show_exercises"),
               br(),
               downloadButton('download_exercises', 'Download as .zip'),
               tags$hr(),
               downloadButton('download_project', 'Download project'),
               br(), br()
      ),
      tabPanel("Define Exams",
               fluidRow(
                 column(6,
                        br(),
                        textInput("exam_name", "Name of the exam.", "Exam1"),
                        p("Select exercises for your exam."),
                        chooserInput("mychooser", c(), c(), size = 10, multiple = TRUE),
                        br(),
                        actionButton("save_exam", label = "Save")
                 ),
                 column(6,
                        br(),
                        p("Exam structure."),
                        uiOutput("exercises4exam")
                 )
               )
      ),
      tabPanel("Generate Exams",
               br(),
               p("Compile exams, please select input parameters."),
               textInput("name", "Choose an exam name.", value = "Exam1"),
               selectInput("format", "Format.", c("PDF", "HTML", "QTI12")),
               numericInput("n", "Number of copies.", value = 1),
               actionButton("compile", label = "Compile."),
               downloadButton('downloadData', 'Download all files as .zip'),
               br(),
               br(),
               p("Files for download."),
               verbatimTextOutput("exams")
      )
    )
      )
  )
)
