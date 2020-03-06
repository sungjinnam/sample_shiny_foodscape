#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source('functions.R')
load("biM_k30_iter2000_XobjXcompXdep.rda")
load("glm_models.rda")


# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
  titlePanel("Topical representation of food choices"),
   
  fluidRow(
   # column(3, helpText("help text")),
   
   # text input
   column(12, wellPanel(
     textInput("text_input", "foodscape input", 
               "I made a spaghetti dinner because I had all the ingredients and it is easy to make."),
     submitButton("Submit")
   )),
   
   # output display
   column(12,
          dataTableOutput("dep_ext"),
          plotOutput("topic_output_plot", width = "400px", height = "300px"),
          tableOutput("topic_output_list"),
          dataTableOutput("topic_output_desc"),
          dataTableOutput("pred_cat")
   )
  )
  
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  # processing the input text
  process_text <- reactive({
    annotate_text <- cnlp_annotate(input$text_input)
    dep_txt <- consol_deptok(annotate_text)
    dep_txt
  })
  topic_res_prob <- reactive({
    topic_new_doc(mod_post, process_text())
    })
  topic_res_list <- reactive({
    topic_probs <- topic_res_prob()
    topic_res <- sort(topic_probs[which(topic_probs>0)], decreasing=TRUE)
    topic_res
    })
  topic_res_desc <- reactive({
    topics <- as.integer(names(topic_res_list()))
    topics_desc <- lapply(topics, function(topic){
      data.frame(topic=topic,
                 dep=names(sort(mod_post$phi_dep[topic,], decreasing=TRUE)[1:3]), 
                 gov=names(sort(mod_post$phi_gov[topic,], decreasing=TRUE)[1:3]))
    })
    do.call(rbind.data.frame, topics_desc)
  })
  
  pred_categories <- reactive({
    pred_topic <- data.frame(t(matrix(topic_res_prob())))
    colnames(pred_topic) <- paste("X", 1:30, sep ="")
    pred_res <- list(cntx_indv=predict(glm_efft, newdata = pred_topic, type="response"),
                     cntx_effr=predict(glm_food, newdata = pred_topic, type="response"),
                     cntx_food=predict(glm_indv, newdata = pred_topic, type="response"),
                     cntx_scen=predict(glm_scen, newdata = pred_topic, type="response"))
    data.frame(pred_res)
  })
  
  # process the results
  output$dep_ext <- renderDataTable(process_text())
  output$topic_output_plot <- renderPlot(barplot(topic_res_prob(), xlab = "Topics", ylab="Probs"))
  output$topic_output_list <- renderTable({topic_res_list()}, 
                                          options=list(
                                            columns=list(list(title="Topics"), list(title="Probs."))
                                            )
                                          )
  output$topic_output_desc <- renderDataTable({topic_res_desc()})
  output$pred_cat <- renderDataTable({pred_categories()})
}

# Run the application 
shinyApp(ui = ui, server = server)

