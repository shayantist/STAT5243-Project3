# CampusConnect: Event Discovery Platform A/B Test
# Load libraries
library(shiny)
library(dplyr)
library(shinythemes)
library(shinyjs)
library(httr)
library(jsonlite)
library(stringr)
library(dotenv)

# Load environment variables
load_dot_env()

# Setup configurations
GA_TRACKING_ID <- Sys.getenv("GA_TRACKING_ID")
GEMINI_API_KEY <- Sys.getenv("GEMINI_API_KEY")

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
# Function to call Gemini API
call_gemini <- function(prompt, api_key = GEMINI_API_KEY) {
  url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=", api_key)
  request_body <- list(
    contents = list(
      list(
        parts = list(
          list(text = prompt)
        )
      )
    )
  )
  response <- tryCatch({
    POST(
      url = url,
      body = toJSON(request_body, auto_unbox = TRUE),
      add_headers("Content-Type" = "application/json"),
      encode = "json"
    )
  }, error = function(e) {
    return(list(status_code = 500, error = e$message))
  })
  
  # if (is.list(response) && "status_code" %in% names(response)) return(paste("Error:", response))
  if (status_code(response) != 200) return(paste("Error:", content(response, "text")))
  
  content <- content(response, "parsed")
  
  # Extract text from the response structure
  if (!is.null(content$candidates) && 
      length(content$candidates) > 0 && 
      !is.null(content$candidates[[1]]$content) && 
      !is.null(content$candidates[[1]]$content$parts) &&
      length(content$candidates[[1]]$content$parts) > 0 &&
      !is.null(content$candidates[[1]]$content$parts[[1]]$text)) {
    return(content$candidates[[1]]$content$parts[[1]]$text)
  } else {
    return("No response generated.")
  }
}

# Function to prepare event data for the chatbot
prepare_events_for_chatbot <- function(events) {
  events_text <- ""
  for (i in 1:nrow(events)) {
    event <- events[i, ]
    events_text <- paste0(events_text, 
                          "Event ", i, ": ", event$title, 
                          ", Category: ", event$category,
                          ", Date: ", format(event$date, "%b %d, %Y"),
                          ", Time: ", event$time,
                          ", Location: ", event$location,
                          ", Description: ", str_trunc(event$description, 100),
                          "\n\n")
  }
  return(events_text)
}

# Function to track events with Google Analytics
track_event <- function(category, action, label = NULL, value = NULL) {
  print(paste("GA Event:", category, action, ifelse(is.null(label), "", label), ifelse(is.null(value), "", value)))
  # In production, replace with actual GA call
}

# Determine version (A or B) based on user ID or URL parameter
determine_version <- function(session) {
  query <- parseQueryString(session$clientData$url_search)
  if (!is.null(query$version) && query$version %in% c("A", "B")) return(query$version)
  if (!is.null(query$group) && query$group %in% c("A", "B")) return(query$group)
  sample(c("A", "B"), 1)  # Random assignment if no valid parameter
}

#==============================================================================
# EVENT DATA
#==============================================================================
# Load event data and categories from external file
source("event_data.R") # Imports event_data and event_categories

#==============================================================================
# UI DEFINITIONS (MINIMIZED)
#==============================================================================
# CSS Styles for both versions
common_css <- "
.event-image { width: 100%; height: 180px; object-fit: cover; }
.event-title { font-weight: bold; margin: 10px 0; }
.event-detail { margin-bottom: 5px; }
.event-description { margin: 10px 0; }
"

version_a_css <- "
body { font-family: sans-serif; }
.header { background-color: #2c3e50; color: white; padding: 20px 0; margin-bottom: 20px; }
.event-box { border: 1px solid #e0e0e0; padding: 15px; margin-bottom: 20px; background-color: #fff; transition: transform 0.2s; }
.event-box:hover { transform: translateY(-5px); box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
.filter-section { background-color: #f5f5f5; padding: 15px; margin-bottom: 20px; }
.btn-primary { background-color: #2c3e50; border-color: #2c3e50; }
"

version_b_css <- "
body { font-family: 'Poppins', sans-serif; background-color: #f8f9fa; }
.header { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; padding: 25px 0; margin-bottom: 30px; }
.event-card { background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.08); margin-bottom: 25px; transition: all 0.3s ease; }
.event-card:hover { transform: translateY(-10px); box-shadow: 0 15px 25px rgba(0,0,0,0.1); }
.search-container { background-color: white; border-radius: 12px; padding: 20px; margin-bottom: 30px; box-shadow: 0 5px 15px rgba(0,0,0,0.05); }
.btn-gradient { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); border: none; color: white; border-radius: 25px; }
.badge-category { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; padding: 5px 10px; border-radius: 20px; font-size: 12px; display: inline-block; margin: 0 5px 5px 0; }
.chat-container { position: fixed; bottom: 20px; right: 80px; width: 350px; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 25px rgba(0,0,0,0.2); z-index: 1000; background-color: white; transition: all 0.3s ease-in-out; }
.chat-header { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; padding: 15px; font-weight: 600; display: flex; justify-content: space-between; }
.chat-messages { height: 300px; overflow-y: auto; padding: 15px; background-color: #f8f9fa; }
.chat-message { margin-bottom: 10px; max-width: 80%; padding: 10px 15px; border-radius: 15px; font-size: 14px; }
.user-message { background-color: #e1f5fe; color: #01579b; margin-left: auto; border-bottom-right-radius: 5px; }
.bot-message { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; border-bottom-left-radius: 5px; }
.chat-hidden { transform: translateY(calc(100% + 20px)); }
.chat-toggle { position: fixed; bottom: 20px; right: 20px; background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; width: 60px; height: 60px; border-radius: 30px; display: flex; justify-content: center; align-items: center; cursor: pointer; box-shadow: 0 5px 15px rgba(0,0,0,0.2); z-index: 1001; }
.event-image-placeholder { width: 100%; height: 180px; background: linear-gradient(135deg, #f5f5f5 0%, #e0e0e0 100%); display: flex; justify-content: center; align-items: center; color: #999; font-size: 12px; }
"

# VERSION A UI: Traditional / not as fancy interface
header_title <- "CampusConnect"
header_subtitle <- "Discover events on campus at Columbia! (NOTE: All fictional—for now!)"
header_authors <- "Project 3 by Team 11: Shayan Chowdhury (sc4040), Ran Yan (ry2487), Zijun Fu (zf2342), and Tiantian Li (tl3404)"

version_a_ui <- function() {
  fluidPage(
    theme = shinytheme("flatly"),
    tags$head(tags$style(HTML(paste(common_css, version_a_css)))),
    div(class = "header", div(class = "container", h1(header_title), p(header_subtitle), p(header_authors))),
    div(class = "container",
        div(class = "filter-section", fluidRow(
          column(3, div(style = "font-weight: bold", "Category"), 
                 selectizeInput("category_filter", NULL, choices = event_categories, selected = "All", multiple = TRUE, 
                                options = list(placeholder = "Select categories"))),
          column(5, div(style = "font-weight: bold", "Date Range"), dateRangeInput("date_range", NULL, start = Sys.Date(), end = Sys.Date() + 30)),
          column(4, div(style = "font-weight: bold", "Search"), textInput("search_text", NULL, placeholder = "Search events..."))
        )),
        h3("Upcoming Events", class = "mb-4"),
        fluidRow(id = "events_container", uiOutput("event_grid")),
        div(style = "margin-top: 30px; padding: 20px 0; background-color: #f5f5f5; text-align: center;",
            p("© 2025 CampusConnect | Columbia University"))
    )
  )
}

# VERSION B UI: Modern / fancy interface + with AI chatbot using Google's Gemini Flash 1.5
version_b_ui <- function() {
  fluidPage(
    theme = shinytheme("cosmo"),
    tags$head(
      tags$style(HTML(paste(common_css, version_b_css))),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css"),
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap")
    ),
    div(class = "header", div(class = "container", div(class = "row align-items-center",
        div(class = "col-md-8", h1(header_title), p(header_subtitle), p(header_authors)),
        div(class = "col-md-4 text-right", actionButton("suggest_event", "Get Personalized Suggestions", class = "btn-gradient"))
    ))),
    div(class = "container",
        div(class = "search-container", fluidRow(
          column(3, div(style = "font-weight: 600", "I'm interested in"), 
                 selectizeInput("category_filter", NULL, choices = event_categories, selected = "All", multiple = TRUE,
                                options = list(placeholder = "Select categories"))),
          column(5, div(style = "font-weight: 600", "When are you free?"), dateRangeInput("date_range", NULL, start = Sys.Date(), end = Sys.Date() + 30)),
          column(4, div(style = "font-weight: 600", "Looking for something specific?"), textInput("search_text", NULL, placeholder = "Search events..."))
        )),
        div(style = "margin-bottom: 30px;",
            h4("Popular Categories", style = "margin-bottom: 15px;"),
            div(
              actionLink("filter_cs", div(class = "badge-category", "Computer Science")),
              actionLink("filter_finance", div(class = "badge-category", "Finance")),
              actionLink("filter_arts", div(class = "badge-category", "Arts")),
              actionLink("filter_music", div(class = "badge-category", "Music")),
              actionLink("filter_politics", div(class = "badge-category", "Politics"))
            )
        ),
        h3("What's Happening On Campus", style = "font-weight: 600;"),
        div(id = "events_container", uiOutput("event_grid")),
        div(style = "margin-top: 50px; padding: 30px 0; background-color: #f1f1f1; text-align: center; border-radius: 25px 25px 0 0;",
            p("© 2025 CampusConnect | Columbia University"))
    ),
    # Chatbot UI - Fixed so it doesn't overlap with the suggest button
    div(id = "chat_toggle", class = "chat-toggle", icon("comments")),
    div(id = "chat_container", class = "chat-container chat-hidden",
        div(class = "chat-header", span("EventGuide Assistant"), actionButton("minimize_chat", icon("minus"), class = "p-0 border-0")),
        div(id = "chat_messages", class = "chat-messages", uiOutput("chat_display")),
        div(style="display: flex; padding: 10px; border-top: 1px solid #e0e0e0;",
            textInput("chat_input", NULL, placeholder = "Ask about events..."),
            actionButton("send_message", icon("paper-plane"), style = "margin-left: 10px;")
        )
    ),
    # JavaScript for chat show/hide (i.e. enter key sends message)
    tags$script(HTML("
      $(document).ready(function() {
        $('#chat_toggle').on('click', function() {
          $('#chat_container').toggleClass('chat-hidden');
          $('#chat_toggle').toggleClass('d-none');
          Shiny.setInputValue('chat_opened', true);
        });
        $('#minimize_chat').on('click', function() {
          $('#chat_container').addClass('chat-hidden');
          $('#chat_toggle').removeClass('d-none');
          Shiny.setInputValue('chat_minimized', true);
        });
        $('#chat_input').keypress(function(e) {
          if (e.which == 13) { $('#send_message').click(); return false; } 
        });
      });
    "))
  )
}

#==============================================================================
# MAIN APP
#==============================================================================
ui <- function(request) {
  tagList(
    tags$head(tags$script(HTML(paste0("console.log('GA tracking ID: ", GA_TRACKING_ID, "');")))),
    useShinyjs(),
    uiOutput("dynamic_ui")
  )
}

server <- function(input, output, session) {
  
  # Version assignment
  version <- reactive({
    v <- determine_version(session)
    track_event("Experiment", "VersionAssignment", v)
    return(v)
  })
  
  # Event filtering
  filtered_events <- reactive({
    events <- event_data
    
    # Apply category filter if selected
    if (!is.null(input$category_filter) && length(input$category_filter) > 0) {
      # Check if "All" is among selected categories
      if (!("All" %in% input$category_filter)) {
        events <- events %>% filter(category %in% input$category_filter)
      }
    }
    
    # Apply date filter if activated
    if (!is.null(input$date_range)) {
      events <- events %>% filter(date >= input$date_range[1] & date <= input$date_range[2])
    }
    
    # Apply search filter if text is entered
    if (!is.null(input$search_text) && input$search_text != "") {
      search_term <- tolower(input$search_text)
      events <- events %>% filter(grepl(search_term, tolower(title)) | 
                                  grepl(search_term, tolower(description)) |
                                  grepl(search_term, tolower(location)))
    }
    
    return(events)
  })
  
  # Track filter usage
  observeEvent(input$category_filter, { track_event("Filter", "Category", paste(input$category_filter, collapse=", ")) })
  observeEvent(input$date_range, { track_event("Filter", "DateRange", paste(input$date_range[1], "to", input$date_range[2])) })
  observeEvent(input$search_text, { if (!is.null(input$search_text) && input$search_text != "") track_event("Filter", "Search", input$search_text) })
  
  # Quick filters (Version B)
  observeEvent(input$filter_cs, { 
    # Get current selections
    current <- input$category_filter
    if ("All" %in% current) {
      current <- c()
    }
    # Add Computer Science if not already selected
    if (!("Computer Science" %in% current)) {
      current <- c(current, "Computer Science")
    }
    updateSelectizeInput(session, "category_filter", selected = current)
    track_event("QuickFilter", "Category", "Computer Science") 
  })
  
  observeEvent(input$filter_finance, { 
    current <- input$category_filter
    if ("All" %in% current) {
      current <- c()
    }
    if (!("Finance" %in% current)) {
      current <- c(current, "Finance")
    }
    updateSelectizeInput(session, "category_filter", selected = current)
    track_event("QuickFilter", "Category", "Finance") 
  })
  
  observeEvent(input$filter_arts, { 
    current <- input$category_filter
    if ("All" %in% current) {
      current <- c()
    }
    if (!("Arts" %in% current)) {
      current <- c(current, "Arts")
    }
    updateSelectizeInput(session, "category_filter", selected = current)
    track_event("QuickFilter", "Category", "Arts") 
  })
  
  observeEvent(input$filter_music, { 
    current <- input$category_filter
    if ("All" %in% current) {
      current <- c()
    }
    if (!("Music" %in% current)) {
      current <- c(current, "Music")
    }
    updateSelectizeInput(session, "category_filter", selected = current)
    track_event("QuickFilter", "Category", "Music") 
  })
  
  observeEvent(input$filter_politics, { 
    current <- input$category_filter
    if ("All" %in% current) {
      current <- c()
    }
    if (!("Politics" %in% current)) {
      current <- c(current, "Politics")
    }
    updateSelectizeInput(session, "category_filter", selected = current)
    track_event("QuickFilter", "Category", "Politics") 
  })
  
  # Render UI based on version
  output$dynamic_ui <- renderUI({ if (version() == "A") version_a_ui() else version_b_ui() })
  
  # Render event grid
  output$event_grid <- renderUI({
    req(filtered_events())
    events <- filtered_events()
    
    if (nrow(events) == 0) {
      return(div(style = "text-align: center; padding: 40px 0;", h4("No events found matching your criteria.")))
    }
    
    if (version() == "A") {
      # Version A event boxes
      event_boxes <- lapply(1:nrow(events), function(i) {
        event <- events[i, ]
        column(width = 4, div(class = "event-box",
          # div(class = "event-image-placeholder", "Event Image"),
          # img(src = event$image_url, class = "event-image"), # TODO: Add actual images?
          div(class = "event-title", event$title),
          div(class = "event-detail", icon("calendar"), " ", format(event$date, "%b %d, %Y")),
          div(class = "event-detail", icon("clock"), " ", event$time),
          div(class = "event-detail", icon("map-marker-alt"), " ", event$location),
          div(class = "event-description", str_trunc(event$description, 120)),
          div(style = "margin-top: 15px;",
            actionButton(paste0("view_details_", event$id), "View Details", class = "btn-sm btn-primary", 
                         onclick = paste0("Shiny.setInputValue('event_details', ", event$id, ");")),
            actionButton(paste0("add_calendar_", event$id), "Add to Calendar", class = "btn-sm btn-outline-primary ml-2", 
                         onclick = paste0("Shiny.setInputValue('add_to_calendar', ", event$id, ");"))
          )
        ))
      })
    } else {
      # Version B event cards
      event_boxes <- lapply(1:nrow(events), function(i) {
        event <- events[i, ]
        column(width = 4, div(class = "event-card",
          # div(class = "event-image-placeholder", "Event Image"),
          # img(src = event$image_url, class = "event-image"), # TODO: Add actual images?
          div(style = "padding: 20px;",
            div(class = "badge-category", event$category),
            div(class = "event-title", event$title),
            div(class = "event-detail", icon("calendar"), " ", format(event$date, "%b %d, %Y")),
            div(class = "event-detail", icon("clock"), " ", event$time),
            div(class = "event-detail", icon("map-marker-alt"), " ", event$location),
            div(class = "event-description", str_trunc(event$description, 100)),
            div(style = "display: flex; gap: 10px; margin-top: 15px;",
              actionButton(paste0("view_details_", event$id), "View Details", class = "btn-gradient", 
                           onclick = paste0("Shiny.setInputValue('event_details', ", event$id, ");")),
              actionButton(paste0("add_calendar_", event$id), "Add to Calendar", class = "btn-outline", 
                           onclick = paste0("Shiny.setInputValue('add_to_calendar', ", event$id, ");"))
            )
          )
        ))
      })
    }
    
    # Arrange in rows of 3
    event_rows <- list()
    for (i in seq(1, length(event_boxes), by = 3)) {
      end_idx <- min(i + 2, length(event_boxes))
      event_rows <- c(event_rows, list(fluidRow(event_boxes[i:end_idx])))
    }
    
    return(do.call(tagList, event_rows))
  })
  
  # Event details modal
  observeEvent(input$event_details, {
    req(input$event_details)
    event_id <- input$event_details
    event <- event_data[event_data$id == event_id, ]
    
    if (nrow(event) == 1) {
      track_event("Interaction", "ViewEventDetails", event$title)
      
      showModal(modalDialog(
        title = event$title,
        div(
          div(style = "text-align: center; margin-bottom: 20px;",
              div(class = "event-image-placeholder", style = "height: 200px; border-radius: 8px;", "Event Image")),
          div(icon("calendar"), " ", format(event$date, "%A, %B %d, %Y")),
          div(icon("clock"), " ", event$time),
          div(icon("map-marker-alt"), " ", event$location),
          div(icon("users"), " ", "Organized by: ", event$organizer),
          hr(), h4("Description"), p(event$description),
          if (event$registration_required) div(hr(), h4("Registration"), p("This event requires registration.")) else div()
        ),
        footer = tagList(
          actionButton("add_to_calendar_modal", "Add to Calendar", 
                       onclick = paste0("Shiny.setInputValue('add_to_calendar', ", event_id, ");"),
                       class = if(version() == "A") "btn-outline-primary" else "btn-outline"),
          modalButton("Close")
        ),
        size = "m", easyClose = TRUE
      ))
    }
  })
  
  # Add to calendar action
  observeEvent(input$add_to_calendar, {
    req(input$add_to_calendar)
    event_id <- input$add_to_calendar
    event <- event_data[event_data$id == event_id, ]
    
    if (nrow(event) == 1) {
      track_event("Conversion", "AddToCalendar", event$title, 1)
      showNotification(paste("Added to calendar:", event$title), type = "default", duration = 5)
      removeModal()
    }
  })
  
  # Chatbot functionality (Version B)
  chat_history <- reactiveValues(messages = character(0))
  
  observeEvent(input$send_message, {
    req(input$chat_input, version() == "B")
    user_msg <- input$chat_input
    track_event("Interaction", "ChatMessage", substr(user_msg, 1, 50))
    
    chat_history$messages <- c(chat_history$messages, paste0("You: ", user_msg))
    
    # Get relevant events to provide to the chatbot
    relevant_events <- event_data
    
    # If the user message contains category keywords, filter events
    categories <- sapply(event_categories[-1], function(cat) {
      if (grepl(tolower(cat), tolower(user_msg))) {
        return(TRUE)
      }
      return(FALSE)
    })
    
    # If categories are found in the message, filter events
    if (any(categories)) {
      filtered_categories <- event_categories[-1][categories]
      relevant_events <- event_data %>% filter(category %in% filtered_categories)
    }
    
    # If we have too many events, limit to most recent ones
    if (nrow(relevant_events) > 10) {
      relevant_events <- relevant_events %>% 
        arrange(date) %>%
        head(10)
    }
    
    # Prepare events data for the chatbot
    events_text <- prepare_events_for_chatbot(relevant_events)
    
    context <- paste0(
      "You are EventGuide, a helpful assistant for the CampusConnect app at Columbia University. ",
      "Keep responses concise (2-3 sentences) and focus on helping users find events. ",
      "Here are some events that might be relevant to the user's query:\n\n",
      events_text,
      "\nUser question: ", user_msg
    )
    
    # TODO: have some sort of loading indicator?
    response <- call_gemini(context)
    
    chat_history$messages <- c(chat_history$messages, paste0("EventGuide: ", response))
    updateTextInput(session, "chat_input", value = "")
  })
  
  output$chat_display <- renderUI({
    req(version() == "B")
    
    if (length(chat_history$messages) == 0) {
      return(div(div(p("Hi there! I'm EventGuide, your personal assistant for finding events at Columbia. What kinds of events interest you?"), 
                      class = "chat-message bot-message")))
    } else {
      chat_elements <- lapply(chat_history$messages, function(msg) {
        if (startsWith(msg, "You: ")) {
          div(p(substr(msg, 6, nchar(msg))), class = "chat-message user-message")
        } else if (startsWith(msg, "EventGuide: ")) {
          div(p(substr(msg, 13, nchar(msg))), class = "chat-message bot-message")
        }
      })
      return(div(chat_elements))
    }
  })
  
  # Suggestion button (Version B)
  observeEvent(input$suggest_event, {
    req(version() == "B")
    track_event("Interaction", "RequestSuggestions")
    
    # Get a list of upcoming events to suggest
    upcoming_events <- event_data %>%
      filter(date >= Sys.Date()) %>%
      arrange(date) %>%
      head(5)
    
    # Provide event data to the chatbot
    events_text <- prepare_events_for_chatbot(upcoming_events)
    
    context <- paste0(
      "You are EventGuide, a helpful assistant for the CampusConnect app at Columbia University. ",
      "The user clicked on 'Get Personalized Suggestions'. Suggest they look at these upcoming events:\n\n",
      events_text,
      "\nKeep your response concise (2-3 sentences) and enthusiastic."
    )
    
    # TODO: have some sort of loading indicator?
    response <- call_gemini(context)
    
    chat_history$messages <- c(chat_history$messages, paste0("EventGuide: ", response))
    runjs("$('#chat_container').removeClass('chat-hidden'); $('#chat_toggle').addClass('d-none');")
  })
  
  # Track chat interactions
  observeEvent(input$chat_opened, { track_event("Interaction", "ChatOpened") })
  observeEvent(input$chat_minimized, { track_event("Interaction", "ChatMinimized") })
  
  # Session duration tracking
  session_start <- Sys.time()
  onSessionEnded(function() {
    session_duration <- as.numeric(difftime(Sys.time(), session_start, units = "secs"))
    track_event("Engagement", "SessionDuration", value = round(session_duration))
  })  
}

# Run the app
shinyApp(ui = ui, server = server)