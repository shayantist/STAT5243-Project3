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
GEMINI_MODEL <- "gemini-1.5-flash"
#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
# Function to call Gemini API
call_gemini <- function(prompt, api_key = GEMINI_API_KEY) {
  url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/", GEMINI_MODEL, ":generateContent?key=", api_key)
  request_body <- list(
    contents = list(
      list(
        parts = list(
          list(text = prompt)
        )
      )
    ),
    generationConfig = list(temperature = 0.8)
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

# Function to store user calendar (only in browser session, not persistent!!)
# TODO: maybe make it persistent by storing in cookies or local storage?
user_calendar <- reactiveValues(events = data.frame())

# Function to add events to calendar
add_event_to_calendar <- function(event_id, event_data) {
  event <- event_data[event_data$id == event_id, ]
  if (nrow(event) == 1) {
    # Check if event is already in calendar
    if (nrow(user_calendar$events) > 0 && event_id %in% user_calendar$events$id) {
      return(FALSE)  # Event already exists
    }
    user_calendar$events <- rbind(user_calendar$events, event)
    return(TRUE)
  }
  return(FALSE)
}

# Function to format events as a string
format_events_to_string <- function(events) {
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

# Function to track events with Google Analytics (GA4 using gtag.js via shinyjs)
track_event <- function(category, action, label = NULL, value = NULL) {
  # Although GA_TRACKING_ID isn't directly used in the gtag JS call here (it relies on the initial config),
  # checking it ensures tracking is intended to be active.
  if (Sys.getenv("GA_TRACKING_ID", "") == "") {
    warning("GA_TRACKING_ID environment variable not set. GA event tracking disabled.")
    return()
  }

  # GA4 uses an event 'name' and 'parameters'.
  # We'll map the old UA structure to the GA4 structure.
  # 'action' seems like a good fit for the GA4 event 'name'.
  # 'category', 'label', and 'value' will become parameters.
  event_name <- action
  event_params <- list()

  # Add parameters if they are not NULL
  if (!is.null(category)) {
    event_params$event_category <- category
  }
  if (!is.null(label)) {
    event_params$event_label <- label
  }
  if (!is.null(value)) {
    # Ensure value is numeric for GA4 standard 'value' parameter
    if(is.numeric(value)) {
      event_params$value <- value
    } else {
       # If value is not numeric, send it as a custom parameter or label extension
       event_params$event_value_detail <- as.character(value)
       warning(paste("GA Event:", event_name, "- Non-numeric value provided. Sent as 'event_value_detail' parameter."))
    }
  }

  # Convert the parameters list to a JSON string suitable for JavaScript
  # Make sure single values are not treated as arrays
  params_json <- jsonlite::toJSON(event_params, auto_unbox = TRUE)

  # print(paste("GA4 Event:", event_name, "| Params:", params_json))

  # Construct the JavaScript command
  # Use single quotes inside the JS string for the event name
  # Use the JSON string for the parameters object
  js_command <- sprintf("if (typeof gtag === 'function') { gtag('event', '%s', %s); console.log('GA4 Event Triggered:', '%s', %s); } else { console.warn('gtag function not found. GA event not sent.'); }",
                        gsub("'", "\\'", event_name, fixed = TRUE), # Escape single quotes in event name
                        params_json,
                        event_name,
                        params_json)

  # Use shinyjs to run the JavaScript command in the browser
  tryCatch({
    shinyjs::runjs(js_command)
    print(paste("GA4 Event Triggered:", event_name, "| Params:", params_json))
  }, error = function(e) {
    warning(paste("Failed to trigger GA4 event via shinyjs:", e$message))
  })
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
# Load event_data and event_categories from external file
source("event_data.R")

#==============================================================================
# FRONTEND UI
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
body { font-family: 'Poppins', sans-serif; background-color: #f8f9fa; } h1, h4 { font-weight: bold; }
.header { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: white; padding: 25px 0; margin-bottom: 15px; }
.event-card { background-color: white; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.08); margin-bottom: 25px; transition: all 0.3s ease; }
.event-card:hover { transform: translateY(-10px); box-shadow: 0 15px 25px rgba(0,0,0,0.1); }
.search-container { background-color: white; border-radius: 12px; padding: 20px; margin-bottom: 15px; box-shadow: 0 5px 15px rgba(0,0,0,0.05); }
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
.form-control { height: 34px; }
"

header_title <- "👑 CampusConnect"
header_subtitle <- "Discover events on campus at Columbia! (NOTE: All fictional—for now!)"
header_authors <- "Project 3 by Team 11: Shayan Chowdhury (sc4040), Ran Yan (ry2487), Zijun Fu (zf2342), and Tiantian Li (tl3404)"
footer_text <- "© 2025 CampusConnect | STAT 5243: Team 11 (Spring 2025)"
date_range_default <- c(Sys.Date() - 30, Sys.Date() + 60)

# VERSION A UI: Traditional / not as fancy interface
version_a_ui <- function() {
  fluidPage(
    tags$head(includeHTML("google-analytics.html")), # Add Google Analytics tracking
    theme = shinytheme("flatly"),
    tags$head(tags$style(HTML(paste(common_css, version_a_css)))),
    div(class = "header", div(class = "container", 
        div(class = "row align-items-center",
            div(class = "col-md-8", h1(header_title), p(header_subtitle), p(header_authors)),
            div(class = "col-md-4 text-right", 
                actionButton("view_calendar", "My Calendar", 
                             class = "btn btn-primary", 
                             icon = icon("calendar"))
            )
        ))),
    div(class = "container",
        div(class = "filter-section", fluidRow(
          column(3, div(style = "font-weight: bold", "Category"), 
                 selectizeInput("category_filter", NULL, choices = event_categories, selected = "All", multiple = TRUE, 
                                options = list(placeholder = "Select categories"))),
          column(5, div(style = "font-weight: bold", "Date Range"), dateRangeInput("date_range", NULL, start = date_range_default[1], end = date_range_default[2])),
          column(4, div(style = "font-weight: bold", "Search"), textInput("search_text", NULL, placeholder = "Search events..."))
        )),
        h3("Upcoming Events", class = "mb-4"),
        fluidRow(id = "events_container", uiOutput("event_grid")),
        div(style = "margin-top: 30px; padding: 20px 0; background-color: #f5f5f5; text-align: center;", p(footer_text))
    )
  )
}

# VERSION B UI: Modern / fancy interface + with AI chatbot using Google's Gemini Flash 1.5
chatbot_intro <- "Hi there! I'm EventGuide, a personal assistant for finding events at Columbia, powered by Google's Gemini 1.5 Flash LLM. What kinds of events interest you? Feel free to ask me anything in natural language."
chatbot_sys_prompt <- "You are EventGuide, a helpful assistant for the CampusConnect app at Columbia University. Keep responses concise (2-3 sentences) and focus on helping users find events. "
popular_categories <- c("Computer Science", "Finance", "Dance", "Politics")

version_b_ui <- function() {
  fluidPage(
    tags$head(includeHTML("google-analytics.html")), # Add Google Analytics tracking
    theme = shinytheme("cosmo"),
    tags$head(
      tags$style(HTML(paste(common_css, version_b_css))),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css"),
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap")
    ),
    div(class = "header", div(class = "container", div(class = "row align-items-center",
        div(class = "col-md-8", h1(header_title), p(header_subtitle), p(header_authors)),
        div(class = "col-md-4 text-right", 
            actionButton("view_calendar", "My Calendar", class = "btn-gradient", icon = icon("calendar")),
            actionButton("suggest_event", "🤖 AI Suggestions", class = "btn-gradient ml-2 mt-2")
        )
    ))),
    div(class = "container",
        div(class = "search-container", fluidRow(
          column(3, div(style = "font-weight: 600", "I'm interested in"), 
                 selectizeInput("category_filter", NULL, choices = event_categories, selected = "All", multiple = TRUE, options = list(placeholder = "Select categories"))),
          column(5, div(style = "font-weight: 600", "When are you free?"), dateRangeInput("date_range", NULL, start = date_range_default[1], end = date_range_default[2])),
          column(4, div(style = "font-weight: 600", "Looking for something specific?"), textInput("search_text", NULL, placeholder = "Search events..."))
        )),
        div(h4("Popular Categories"),
            div(lapply(popular_categories, function(category) {
              actionLink(paste0("filter_", tolower(gsub(" ", "_", category))), 
                          div(class = "badge-category", category))
            })
          )
        ),
        h3("What's Happening On Campus", style = "font-weight: 600;"),
        div(id = "events_container", uiOutput("event_grid")),
        div(style = "margin-top: 50px; padding: 30px 0; background-color: #f1f1f1; text-align: center; border-radius: 25px 25px 0 0;", p(footer_text))
    ),
    # Chatbot UI
    div(id = "chat_toggle", class = "chat-toggle", icon("comments")),
    div(id = "chat_container", class = "chat-container chat-hidden",
        div(class = "chat-header", span("EventGuide LLM Chatbot"), actionButton("minimize_chat", icon("minus"), class = "p-0 border-0")),
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
# MAIN APP (SERVER + UI)
#==============================================================================
ui <- function(request) {
  tagList(
    tags$head(tags$script(HTML(paste0("console.log('GA tracking ID: ", GA_TRACKING_ID, "');")))),
    useShinyjs(),
    uiOutput("dynamic_ui")
  )
}

server <- function(input, output, session) {
  # Wait for GA to be initialized
  while (Sys.getenv("GA_TRACKING_ID", "") == "") {
    Sys.sleep(0.5)
  }

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
  observeEvent(input$category_filter, { track_event("Filter", "CategoryFilter", paste(input$category_filter, collapse=", ")) })
  observeEvent(input$date_range, { track_event("Filter", "DateRangeFilter", paste(input$date_range[1], "to", input$date_range[2])) })
  observeEvent(input$search_text, { if (!is.null(input$search_text) && input$search_text != "") track_event("Filter", "Search", input$search_text) })
  
  # Quick filters (Version B) - dynamically create observers for each category
  lapply(popular_categories, function(category) {
    filter_id <- paste0("filter_", tolower(gsub(" ", "_", category)))
    observeEvent(input[[filter_id]], {
      current <- input$category_filter
      if ("All" %in% current) {
        current <- c()
      }
      if (!(category %in% current)) {
        current <- c(category)
      }
      updateSelectizeInput(session, "category_filter", selected = current)
      track_event("QuickFilter", "CategoryFilter", category)
    })
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
      result <- add_event_to_calendar(event_id, event_data)
      if (result) {
        track_event("Conversion", "AddToCalendar", event$title, 1)
        showNotification(paste("Added to calendar:", event$title), type = "message", duration = 5)
      } else {
        showNotification("This event is already in your calendar", type = "warning", duration = 3)
      }
      removeModal()
    }
  })
  
  # View calendar action
  observeEvent(input$view_calendar, {
    track_event("Interaction", "ViewCalendar")
    
    if (nrow(user_calendar$events) == 0) {
      calendar_content <- div(
        style = "text-align: center; padding: 20px;",
        icon("calendar-times", style = "font-size: 48px; color: #ccc;"),
        h4("Your calendar is empty"),
        p("Add events to see them here.")
      )
    } else {
      # Sort events by date
      calendar_events <- user_calendar$events %>% arrange(date)
      
      # Create event list
      event_list <- lapply(1:nrow(calendar_events), function(i) {
        event <- calendar_events[i, ]
        div(
          class = if(version() == "A") "event-box" else "event-card",
          style = "margin-bottom: 15px; padding: 15px;",
          div(class = "event-title", event$title),
          div(class = "event-detail", icon("calendar"), " ", format(event$date, "%b %d, %Y")),
          div(class = "event-detail", icon("clock"), " ", event$time),
          div(class = "event-detail", icon("map-marker-alt"), " ", event$location),
          actionButton(paste0("remove_calendar_", event$id), "Remove", 
                       class = if(version() == "A") "btn-sm btn-outline-danger" else "btn-sm btn-outline",
                       onclick = paste0("Shiny.setInputValue('remove_from_calendar', ", event$id, ");"))
        )
      })
      
      calendar_content <- div(
        h4("Your Upcoming Events", style = "margin-bottom: 20px;"),
        div(event_list)
      )
    }
    
    showModal(modalDialog(
      title = "My Calendar",
      calendar_content,
      size = "m", easyClose = TRUE
    ))
  })
  
  # Remove from calendar action
  observeEvent(input$remove_from_calendar, {
    req(input$remove_from_calendar)
    event_id <- input$remove_from_calendar
    
    if (nrow(user_calendar$events) > 0) {
      event_to_remove <- user_calendar$events[user_calendar$events$id == event_id, ]
      if (nrow(event_to_remove) > 0) {
        user_calendar$events <- user_calendar$events[user_calendar$events$id != event_id, ]
        track_event("Interaction", "RemoveFromCalendar", event_to_remove$title)
        showNotification(paste("Removed from calendar:", event_to_remove$title), type = "default", duration = 3)
        
        # Refresh the calendar modal
        removeModal()
        delay(300, {
          if(input$view_calendar > 0) {
            runjs("$('#view_calendar').click();")
          }
        })
      }
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
    
    # TODO: implement a better way to filter events based on the user's message
    # # If the user message contains category keywords, filter events
    # categories <- sapply(event_categories[-1], function(cat) {
    #   if (grepl(tolower(cat), tolower(user_msg))) {
    #     return(TRUE)
    #   }
    #   return(FALSE)
    # })
    
    # # If categories are found in the message, filter events
    # if (any(categories)) {
    #   filtered_categories <- event_categories[-1][categories]
    #   relevant_events <- event_data %>% filter(category %in% filtered_categories)
    # }
    
    # # If we have too many events, limit to most recent ones
    # if (nrow(relevant_events) > 10) {
    #   relevant_events <- relevant_events %>% 
    #     arrange(date) %>%
    #     head(10)
    # }
    
    context <- paste0(chatbot_sys_prompt,
      "Here are some events that might be relevant to the user's query:\n\n",
      format_events_to_string(relevant_events),
      "\nUser question: ", user_msg
    )
    
    # TODO: have some sort of loading indicator in the chatbot box
    showModal(modalDialog(
      title = "Generating response...",
      div(class = "spinner-border text-primary", role = "status"),
      size = "m", easyClose = TRUE
    ))
    response <- call_gemini(context)
    removeModal()

    chat_history$messages <- c(chat_history$messages, paste0("EventGuide: ", response))
    updateTextInput(session, "chat_input", value = "")
  })
  
  output$chat_display <- renderUI({
    req(version() == "B")
    
    if (length(chat_history$messages) == 0) {
      return(div(div(p(chatbot_intro), class = "chat-message bot-message")))
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
  
  # AI suggestions button (Version B)
  observeEvent(input$suggest_event, {
    req(version() == "B")
    track_event("Interaction", "RequestSuggestions")
    
    # Get user's calendar events
    calendar_events <- user_calendar$events
    
    if (nrow(calendar_events) > 0) {
      # Get the categories of events in the calendar
      calendar_categories <- unique(calendar_events$category)
      
      # Find events with similar categories, not already in calendar
      suggested_events <- event_data %>%
        filter(category %in% calendar_categories) %>%
        filter(!id %in% calendar_events$id) %>%
        filter(date >= Sys.Date()) %>%
        arrange(date) %>%
        head(5)
      
      # If no similar events found, get random events
      if (nrow(suggested_events) == 0) {
        suggested_events <- event_data %>%
          filter(!id %in% calendar_events$id) %>%
          filter(date >= Sys.Date()) %>%
          sample_n(min(5, nrow(.)))
      }
      
      # Context for recommendation based on calendar
      context <- paste0(chatbot_sys_prompt,
        "The user has these events in their calendar: \n\n",
        format_events_to_string(calendar_events),
        "\n\nBased on their interests, recommend these similar events: \n\n",
        format_events_to_string(suggested_events),
        "\nExplain why these recommendations match their interests. Keep your response concise (2-3 sentences) and enthusiastic."
      )
    } else {
      # If calendar is empty, recommend random upcoming events
      suggested_events <- event_data %>%
        filter(date >= Sys.Date()) %>%
        arrange(date) %>%
        head(5)
      
      # Context for recommendation with empty calendar
      context <- paste0(chatbot_sys_prompt,
        "The user doesn't have any events in their calendar yet. Here are some events you can recommend: \n\n",
        format_events_to_string(suggested_events),
        "\nKeep your response concise (2-3 sentences) and enthusiastic, encouraging them to explore these events."
      )
    }
    
    # Call Gemini for recommendations
    response <- call_gemini(context)
    
    # Add recommendation to chat and open chat
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