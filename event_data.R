# This file contains dummy event data for CampusConnect application (in app.R)
# NOTE FOR FULL DISCLOSURE: This data was generated using Anthropic's Claude Sonnet 3.7 large language model
# as suggested by our last guest speaker, LLMs are great at generating dummy data!

# Create a dataframe with events
event_data <- data.frame(
  id = 1:25,
  title = character(25),
  category = character(25),
  date = as.Date(character(25)),
  time = character(25),
  location = character(25),
  description = character(25),
  image_url = character(25),
  organizer = character(25),
  registration_required = logical(25),
  registration_link = character(25),
  stringsAsFactors = FALSE
)

# Computer Science Events
event_data[1, ] <- list(
  1,
  "AI Ethics Workshop: Bias in Machine Learning",
  "Computer Science",
  as.Date("2025-05-15"),
  "2:00 PM - 5:00 PM",
  "Davis Auditorium, CEPSR",
  "Join renowned AI ethics researcher Dr. Timnit Gebru for a hands-on workshop exploring bias in machine learning systems and how to build more equitable AI. Open to all skill levels.",
  "cs_event1.jpg",
  "Columbia Computer Science Department",
  TRUE,
  "https://cs.columbia.edu/events/ai-ethics"
)

event_data[2, ] <- list(
  2,
  "Hackathon: Build for Social Good",
  "Computer Science",
  as.Date("2025-05-20"),
  "9:00 AM - 9:00 PM",
  "Mudd Building, 4th Floor",
  "A 12-hour hackathon focused on building solutions for local non-profits. Form teams or join one on-site. Prizes include internship interviews with Google and funding opportunities.",
  "cs_event2.jpg",
  "Columbia Engineering Student Council",
  TRUE,
  "https://engineering.columbia.edu/hackathon"
)

event_data[3, ] <- list(
  3,
  "From Classroom to Silicon Valley: CS Career Panel",
  "Computer Science",
  as.Date("2025-05-10"),
  "6:00 PM - 8:00 PM",
  "Schapiro Hall, Room 415",
  "Alumni from top tech companies including Google, Meta, and several successful startups share their career journeys and advice on breaking into the industry. Networking reception to follow.",
  "cs_event3.jpg",
  "Columbia CS Alumni Association",
  FALSE,
  ""
)

event_data[4, ] <- list(
  4,
  "Introduction to Quantum Computing",
  "Computer Science",
  as.Date("2025-05-25"),
  "4:00 PM - 6:00 PM",
  "Pupin Hall, Room 301",
  "Professor John Preskill from Columbia's Quantum Initiative explains quantum computing principles and their potential to revolutionize computation. No physics background required.",
  "cs_event4.jpg",
  "Columbia Quantum Initiative",
  FALSE,
  ""
)

# Finance Events
event_data[5, ] <- list(
  5,
  "Wall Street Case Competition Finals",
  "Finance",
  as.Date("2025-05-12"),
  "5:00 PM - 9:00 PM",
  "Uris Hall, Room 301",
  "Watch top teams present their solutions to a real M&A case. Judges include executives from Goldman Sachs, Morgan Stanley, and Blackstone. Networking reception with refreshments.",
  "finance_event1.jpg",
  "Columbia Business School Finance Club",
  TRUE,
  "https://business.columbia.edu/case-competition"
)

event_data[6, ] <- list(
  6,
  "Cryptocurrency Investing Workshop",
  "Finance",
  as.Date("2025-05-18"),
  "1:00 PM - 3:00 PM",
  "Warren Hall, Room 209",
  "Learn about blockchain technology, cryptocurrency fundamentals, and portfolio management strategies from CoinBase's head of research. Bring your laptop for interactive demonstrations.",
  "finance_event2.jpg",
  "Columbia Blockchain Alliance",
  TRUE,
  "https://cba.columbia.edu/crypto-workshop"
)

event_data[7, ] <- list(
  7,
  "Venture Capital Pitch Day",
  "Finance",
  as.Date("2025-05-22"),
  "3:00 PM - 7:00 PM",
  "Columbia Startup Lab, SoHo",
  "Student entrepreneurs pitch their startups to a panel of NYC-based VCs with over $2B in assets under management. Opportunity to secure seed funding and advisory relationships.",
  "finance_event3.jpg",
  "Columbia Entrepreneurship",
  TRUE,
  "https://entrepreneurship.columbia.edu/pitch-day"
)

# Dance Events
event_data[8, ] <- list(
  8,
  "Orchesis Spring Showcase: Momentum",
  "Dance",
  as.Date("2025-05-16"),
  "7:30 PM - 9:30 PM",
  "Roone Arledge Auditorium",
  "Columbia's largest dance group presents their spring performance featuring over 30 original student choreographed pieces spanning ballet, contemporary, hip-hop, and more.",
  "dance_event1.jpg",
  "Columbia Orchesis",
  TRUE,
  "https://arts.columbia.edu/orchesis-spring"
)

event_data[9, ] <- list(
  9,
  "Street Dance Workshop with Jabbawockeez Member",
  "Dance",
  as.Date("2025-05-11"),
  "2:00 PM - 4:00 PM",
  "Dodge Fitness Center, Studio 3",
  "Learn from Kevin 'Konkrete' Davis, member of the world-famous Jabbawockeez crew. This workshop covers popping, locking, and hip-hop foundations. All experience levels welcome.",
  "dance_event2.jpg",
  "Columbia University Dance Marathon",
  TRUE,
  "https://cudm.columbia.edu/workshop"
)

event_data[10, ] <- list(
  10,
  "Traditional Indian Dance Workshop",
  "Dance",
  as.Date("2025-05-19"),
  "6:00 PM - 8:00 PM",
  "Lerner Hall, Room 555",
  "Learn the basics of Bharatanatyam and Kathak from members of Columbia Raas and CU Bhangra. No prior experience needed. Traditional snacks provided.",
  "dance_event3.jpg",
  "South Asian Students Association",
  FALSE,
  ""
)

# Music Events
event_data[11, ] <- list(
  11,
  "Columbia Jazz Ensemble: Spring Concert",
  "Music",
  as.Date("2025-05-17"),
  "8:00 PM - 10:00 PM",
  "Miller Theatre",
  "The award-winning Columbia Jazz Ensemble performs classics and original compositions. Special guest appearance by Grammy-nominated trumpeter Ambrose Akinmusire.",
  "music_event1.jpg",
  "Columbia University Arts Initiative",
  TRUE,
  "https://arts.columbia.edu/jazz-spring"
)

event_data[12, ] <- list(
  12,
  "Acapella Spring Jam",
  "Music",
  as.Date("2025-05-13"),
  "7:00 PM - 9:00 PM",
  "St. Paul's Chapel",
  "Columbia's premier acapella groups including Notes and Keys, Nonsequitur, and Uptown Vocal come together for a night of harmony, featuring special arrangements of contemporary hits.",
  "music_event2.jpg",
  "Columbia Acapella Council",
  TRUE,
  "https://cac.columbia.edu/spring-jam"
)

event_data[13, ] <- list(
  13,
  "Electronic Music Production Workshop",
  "Music",
  as.Date("2025-05-21"),
  "5:00 PM - 7:00 PM",
  "Computer Music Center, Prentis Hall",
  "Introduction to Ableton Live led by Columbia's Computer Music Center staff. Learn the basics of music production, synthesis, and sampling. Bring headphones and laptops with Ableton installed (trial version OK).",
  "music_event3.jpg",
  "Columbia Computer Music Center",
  TRUE,
  "https://music.columbia.edu/cmc/workshop"
)

# Theater Events
event_data[14, ] <- list(
  14,
  "NOMADS Original Play: 'The Algorithm'",
  "Theater",
  as.Date("2025-05-14"),
  "8:00 PM - 10:00 PM",
  "Lerner Black Box Theatre",
  "An original student-written play exploring the intersection of technology and humanity. When an AI begins to show consciousness, its creators must confront ethical dilemmas about what it means to be human.",
  "theater_event1.jpg",
  "Columbia NOMADS Theater Group",
  TRUE,
  "https://arts.columbia.edu/nomads-algorithm"
)

event_data[15, ] <- list(
  15,
  "Shakespeare in the Quad: A Midsummer Night's Dream",
  "Theater",
  as.Date("2025-05-23"),
  "7:00 PM - 9:30 PM",
  "South Lawn",
  "The Columbia Shakespeare Society presents their annual outdoor performance. Bring blankets and enjoy this magical comedy under the stars. Free admission.",
  "theater_event2.jpg",
  "Columbia Shakespeare Society",
  FALSE,
  ""
)

# Debate Events
event_data[16, ] <- list(
  16,
  "Parliamentary Debate Tournament Finals",
  "Debate",
  as.Date("2025-05-09"),
  "3:00 PM - 6:00 PM",
  "Hamilton Hall, Room 602",
  "Watch the culmination of Columbia's spring debate tournament as finalists argue whether artificial intelligence should be regulated as a public utility. Reception to follow.",
  "debate_event1.jpg",
  "Columbia Debate Society",
  FALSE,
  ""
)

event_data[17, ] <- list(
  17,
  "Climate Policy Debate: Market Solutions vs. Government Regulation",
  "Debate",
  as.Date("2025-05-24"),
  "4:00 PM - 6:00 PM",
  "International Affairs Building, Room 1501",
  "Faculty from Columbia's Earth Institute and School of International and Public Affairs debate approaches to addressing climate change. Audience Q&A session included.",
  "debate_event2.jpg",
  "Columbia Climate Coalition",
  TRUE,
  "https://climate.columbia.edu/policy-debate"
)

# Politics Events
event_data[18, ] <- list(
  18,
  "US-China Relations Panel Discussion",
  "Politics",
  as.Date("2025-05-26"),
  "5:30 PM - 7:30 PM",
  "Faculty House, Presidential Ballroom",
  "Distinguished panel featuring Ambassador Wendy Sherman and former Treasury Secretary Jack Lew discussing the future of US-China relations. Moderated by Professor Andrew Nathan.",
  "politics_event1.jpg",
  "Weatherhead East Asian Institute",
  TRUE,
  "https://weai.columbia.edu/us-china-panel"
)

event_data[19, ] <- list(
  19,
  "European Union at a Crossroads: Lecture by EU Parliament President",
  "Politics",
  as.Date("2025-05-27"),
  "6:00 PM - 8:00 PM",
  "Low Library, Rotunda",
  "Roberta Metsola, President of the European Parliament, delivers a keynote address on challenges facing the EU, including migration, climate policy, and economic integration.",
  "politics_event2.jpg",
  "European Institute at Columbia University",
  TRUE,
  "https://europe.columbia.edu/metsola-lecture"
)

event_data[20, ] <- list(
  20,
  "Local Politics Workshop: How to Run for Office",
  "Politics",
  as.Date("2025-05-28"),
  "12:00 PM - 2:00 PM",
  "Journalism School, World Room",
  "Learn the basics of launching a local political campaign from city council members and campaign managers. Topics include fundraising, messaging, and community organizing.",
  "politics_event3.jpg",
  "Columbia Political Union",
  TRUE,
  "https://cpu.columbia.edu/run-for-office"
)

# Additional Interdisciplinary Events
event_data[21, ] <- list(
  21,
  "Climate Tech Innovation Fair",
  "Interdisciplinary",
  as.Date("2025-05-29"),
  "11:00 AM - 4:00 PM",
  "Northwest Corner Building, Lobby",
  "Showcase of student and faculty projects addressing climate change through technology solutions. Featuring prototypes, demos, and opportunities for collaboration across disciplines.",
  "interdisciplinary_event1.jpg",
  "Columbia Climate School",
  FALSE,
  ""
)

event_data[22, ] <- list(
  22,
  "Health Equity Symposium",
  "Interdisciplinary",
  as.Date("2025-05-30"),
  "9:00 AM - 5:00 PM",
  "Mailman School of Public Health, Rosenfield Auditorium",
  "Day-long symposium examining public health disparities through medical, social, economic, and policy lenses. Student poster session during lunch break.",
  "interdisciplinary_event2.jpg",
  "Columbia University Irving Medical Center",
  TRUE,
  "https://cuimc.columbia.edu/health-equity"
)

event_data[23, ] <- list(
  23,
  "Film Festival: New York Through the Lens",
  "Arts",
  as.Date("2025-05-31"),
  "Various times",
  "Lifetime Screening Room, Dodge Hall",
  "Student film showcase featuring short documentaries and narrative films about New York City. Special screening of alumni Oscar-nominated short film with director Q&A.",
  "arts_event1.jpg",
  "Columbia Film School",
  TRUE,
  "https://arts.columbia.edu/film-festival"
)

event_data[24, ] <- list(
  24,
  "Global Career Development Workshop",
  "Career",
  as.Date("2025-06-01"),
  "3:00 PM - 5:00 PM",
  "International Affairs Building, Room 1302",
  "Interactive workshop on building an international career with representatives from the UN, international NGOs, and global companies. Resume review session included.",
  "career_event1.jpg",
  "Center for Career Education",
  TRUE,
  "https://cce.columbia.edu/global-careers"
)

event_data[25, ] <- list(
  25,
  "Sustainable Fashion Show",
  "Arts",
  as.Date("2025-06-02"),
  "7:00 PM - 9:00 PM",
  "Diana Center, Event Oval",
  "Barnard and Columbia student designers showcase innovative fashion created from sustainable and upcycled materials. Panel discussion on ethical fashion follows the runway show.",
  "arts_event2.jpg",
  "Design for Sustainability Collective",
  TRUE,
  "https://arts.columbia.edu/sustainable-fashion"
)

# Add some events located at popular Columbia locations
locations <- c(
  "Butler Library", 
  "Avery Hall", 
  "Philosophy Hall", 
  "Havemeyer Hall", 
  "Mathematics Building",
  "Kent Hall",
  "Lerner Hall",
  "Milbank Hall",
  "Milstein Center",
  "Northwest Corner Building"
)

# Make all image URLs into placeholders
event_data$image_url <- paste0("/api/placeholder/400/250")

# Convert dates to proper Date objects
event_data$date <- as.Date(event_data$date, format="%Y-%m-%d")

# Create categories vector for filtering
event_categories <- c(
  "All",
  "Computer Science",
  "Finance",
  "Dance",
  "Music",
  "Theater",
  "Debate",
  "Politics",
  "Interdisciplinary",
  "Arts",
  "Career"
)