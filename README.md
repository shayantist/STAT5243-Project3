# CampusConnect: Discover Events on Campus

This repository contains an R Shiny web application for event discovery on university campuses (specifically Columbia for now), developed by Team 11 (Shayan Chowdhury, Ran Yen, Zijun Fu, and Tiantian Li) for Prof. Alex Pijyan's STAT5243 Applied Data Science course in Spring 2025. Test it out at [https://shayantist.shinyapps.io/stat5243-project3/](https://shayantist.shinyapps.io/stat5243-project3/)!

As per the assignment instructions, we have also implemented an A/B testing framework to evaluate two different UI approaches for a campus event discovery platform:
- **Version A**: Traditional, less fancy UI with simple list view (directly accessible at [https://shayantist.shinyapps.io/stat5243-project3/?group=A](https://shayantist.shinyapps.io/stat5243-project3/?group=A))
- **Version B**: More modern, interactive UI with an **LLM-powered AI chatbot assistant** using Google's Gemini 1.5 Flash (via Google AI Studio API) (directly accessible at [https://shayantist.shinyapps.io/stat5243-project3/?group=B](https://shayantist.shinyapps.io/stat5243-project3/?group=B))

To test user engagement between the two versions, as suggested in the assignment, we also implemented a basic A/B testing framework using [Google Analytics](https://analytics.google.com/analytics/web/), allowing for statistical analysis of user behavior and preference between the two designs.

## Features
### Core Functionality (Both Versions)
- **Event Discovery**: Browse and filter campus events by category, date range, and keywords
- **Event Details**: View comprehensive information about each event (time, location, description)
- **Calendar Integration**: Add events to personal calendar (primary conversion metric)
- **Analytics Tracking**: Comprehensive event tracking for user behavior analysis

### Version A: Traditional Interface
- Clean, minimalist design with neutral colors
- List-based event display with simple hover effects
- Standard form controls for filtering
- Familiar navigation patterns for broad accessibility

### Version B: Modern Interface with LLM Assistant
- Vibrant gradient color scheme with animated elements
- Card-based event display with enhanced visual hierarchy
- Quick-filter category badges for one-click filtering
- **THE REAL STAR OF THE SHOW**: "EventGuide" AI chatbot assistant powered by Google's Gemini 1.5 Flash
- Personalized event suggestions via AI assistant (based on user's calendar events)

### Analytics Implementation
The application tracks several key metrics to compare the effectiveness of each interface:
1. **Engagement Metrics**
   - Click-through rates on events
   - Time spent browsing
   - Chatbot interactions (specifically for Version B)
2. **Conversion Metrics**
   - "Add to Calendar" actions
   - Event detail views
   - Personalized suggestions requests (specifically for Version B)
3. **Session Metrics**
   - Session duration
   - Return rate
   - Bounce rate

## File Structure
- `[app.R](./app.R)`: Main Shiny application with both UI versions and A/B testing logic
- `[event_data.R](./event_data.R)`: Contains dummy campus event data used by the application (generated using Claude Sonnet 3.7)
- `[google-analytics.html](./google-analytics.html)`: Google Analytics tracking code integration
- `[manifest.json](./manifest.json)`: Configuration file for shinyapps.io deployment
- `[analysis/](./analysis/)`: Directory containing statistical analysis code and data
   - `[statistical_analysis.R](./statistical_analysis.R)`: R script for analyzing experimental results
   - `[groupA.csv](./groupA.csv)` & `[groupB.csv](./groupB.csv)`: Collected experimental data from each group

## Installation and Setup

### Prerequisites
- R (version 4.1.0 or higher)
- The following R packages:
  - dotenv (for loading environment variables)
  - shiny (for the UI)
  - dplyr (for data manipulation)
  - stringr (for string manipulation)
  - shinythemes (for themes)
  - shinyjs (for custom JavaScript to make the LLM chatbot work)
  - httr (for API calls)
  - jsonlite (for parsing JSON from API responses)

### Configuration
1. Clone this repository:
   ```bash
   git clone https://github.com/shayantist/STAT5243-Project3.git
   cd STAT5243-Project3
   ```
2. Install the required packages:
   ```r
   install.packages(c("shiny", "dplyr", "stringr", "shinythemes", "shinyjs", "httr", "jsonlite", "dotenv"))
   ```
3. Configure environment variables:
   - Create a `.env` file in the root directory and add your Google Analytics tracking ID and Gemini API key from Google AI Studio (it's free!!):
   ```r
   GA_TRACKING_ID=G-XXXXXXXX
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
   ```
4. Run the application:
   ```r
   shiny::runApp("app.R")
   ```
5. Access the application in your web browser at `http://localhost:xxxx` (where xxxx is the port number shown in the console)

### A/B Testing Configuration
By default, users are randomly assigned to either Version A or Version B. To force a specific version for testing, use URL parameters:
- Version A: `http://localhost:xxxx/?group=A`
- Version B: `http://localhost:xxxx/?group=B`

## Data Collection and Analysis
### Event Data
The application includes synthetic event data representing a diverse range of campus activities (computer science, finance, arts and culture, academic lectures, social gatherings, etc.).

### Analytics Data
All user interactions are tracked and can be analyzed through:
1. The Google Analytics dashboard
2. Direct processing of the raw event data
3. Custom R scripts for statistical analysis (included in the `/analysis` folder)

## A/B Testing Framework
This application implements best practices for A/B testing:
1. **Random Assignment**: Users are randomly assigned to either Version A or B
2. **Isolation of Variables**: The only differences between versions are UI and the presence of the chatbot
3. **Consistent Metrics**: Both versions track the same core conversion and engagement metrics
4. **Minimized Cross-Contamination**: Users consistently see the same version on return visits