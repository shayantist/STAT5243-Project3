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
   - Filter usage frequency
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
2. Configure environment variables:
   - Create a `.env` file in the root directory and add your Google Analytics tracking ID and Gemini API key from Google AI Studio (it's free!!):
   ```r
   GA_TRACKING_ID=G-XXXXXXXX
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
   ```

### Running the Application

1. Open the project in RStudio and run:
   ```r
   shiny::runApp("app.R")
   ```
2. Or run from the command line:
   ```
   Rscript -e "shiny::runApp('app.R')"
   ```
3. Access the application in your web browser at `http://localhost:xxxx` (where xxxx is the port number shown in the console)

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

## A/B Test Results Summary
We conducted statistical analysis to evaluate whether Version B's redesigned interface and LLM chatbot led to measurable improvements in user engagement.

1. **Conversion Rate**  
- Group A: 92 adds / 380 events = **24.2%**  
- Group B: 139 adds / 465 events = **29.9%**  
- Z-test result: *p = 0.0652*  
→ Version B showed a **5.7% absolute** and **23.6% relative** increase in conversion, though the difference was not statistically significant at the 5% level.

2. **Average Session Duration**  
- Group A: **217.88 seconds**  
- Group B: **294.83 seconds**  
- T-test result: *p < 0.000001*  
→ Version B users spent **+77 seconds** more per session (**+35.3%**), a statistically significant improvement supporting the effectiveness of UI and chatbot enhancements.


## Interpretation & Conclusion
These results indicate that Version B's interface successfully improved user engagement. While the increase in conversion rate was suggestive but not conclusive, the **significant improvement in session duration** suggests that users found the enhanced interface more engaging. The combination of better visuals and a conversational assistant likely contributed to this effect.

To better understand the role of the AI assistant, future work should include more granular event logging (e.g., number of chatbot messages sent), user feedback collection, and factorial testing to isolate UI and AI components.



## Challenges & Limitations
- **No cookie-based persistence**: users might be reassigned between visits
- **AI interactions not separately tracked**: reduced insight into the assistant’s actual impact
- **Short test duration (12 hours)**: may limit generalizability
- **Participants mostly students**: non-representative sample
- **No user satisfaction data**: interaction logs cannot capture subjective perceptions

