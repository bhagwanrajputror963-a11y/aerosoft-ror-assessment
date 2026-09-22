# Idempotent demo data for Flying Crews.
# Run with: bin/rails db:seed
#
# Seeds enough volume (50+ jobs, multiple candidates/companies, and a
# spread of applications) to actually exercise search, pagination, and
# the recruiter/candidate dashboards with real-looking data.

srand(20260922) # deterministic "random" picks so re-seeding is stable

PASSWORD = "password123"

admin = User.find_or_create_by!(email: "admin@flyingcrews.com") do |u|
  u.name = "Site Admin"
  u.role = :admin
  u.password = PASSWORD
end

# --- Companies + recruiters ------------------------------------------------

COMPANY_DEFS = [
  { name: "IndiGo Airlines", location: "Gurugram, India", recruiter: "Priya Sharma", email: "recruiter@indigo.example" },
  { name: "Air India", location: "Delhi, India", recruiter: "Rohan Kapoor", email: "recruiter@airindia.example" },
  { name: "SpiceJet", location: "Gurugram, India", recruiter: "Meera Nair", email: "recruiter@spicejet.example" },
  { name: "Vistara", location: "Gurugram, India", recruiter: "Aditya Rao", email: "recruiter@vistara.example" },
  { name: "Akasa Air", location: "Mumbai, India", recruiter: "Sana Fernandes", email: "recruiter@akasa.example" },
  { name: "Emirates", location: "Dubai, UAE", recruiter: "Fatima Al Marri", email: "recruiter@emirates.example" }
].freeze

recruiters_by_company = COMPANY_DEFS.to_h do |def_|
  company = Company.find_or_create_by!(name: def_[:name]) do |c|
    c.description = "#{def_[:name]} is hiring across pilot, cabin crew, engineering, management, and ground staff roles."
    c.website = "https://example.com"
    c.location = def_[:location]
  end

  recruiter_user = User.find_or_create_by!(email: def_[:email]) do |u|
    u.name = def_[:recruiter]
    u.role = :recruiter
    u.password = PASSWORD
  end

  recruiter = Recruiter.find_or_create_by!(user: recruiter_user) do |r|
    r.company = company
    r.position = "Talent Acquisition Lead"
  end

  [ company.name, recruiter ]
end

indigo_recruiter = recruiters_by_company.fetch("IndiGo Airlines")

# --- Candidates --------------------------------------------------------------

CANDIDATE_DEFS = [
  { name: "Arjun Mehta", email: "candidate@example.com", headline: "Commercial Pilot, 2500 flight hours", skills: "Boeing 737, Airbus A320, CRM", experience_years: 5 },
  { name: "Rina Kapoor", email: "rina@example.com", headline: "Cabin Crew, 3 years experience", skills: "Safety procedures, Customer service", experience_years: 3 },
  { name: "Karan Thakur", email: "karan@example.com", headline: "Licensed AME, narrow-body specialist", skills: "A320, B737, Line Maintenance", experience_years: 6 },
  { name: "Divya Iyer", email: "divya@example.com", headline: "MBA, Aviation Management", skills: "Revenue management, Ops strategy", experience_years: 2 },
  { name: "Vikram Singh", email: "vikram@example.com", headline: "Ground Operations Specialist", skills: "Ramp handling, Baggage systems", experience_years: 4 },
  { name: "Anjali Desai", email: "anjali@example.com", headline: "First Officer, ATR & A320 rated", skills: "ATR72, A320, Multi-crew coordination", experience_years: 7 },
  { name: "Farhan Sheikh", email: "farhan@example.com", headline: "Senior Flight Attendant", skills: "Inflight service, Emergency response", experience_years: 5 },
  { name: "Neha Joshi", email: "neha@example.com", headline: "Fresh graduate, aviation management", skills: "Excel, Customer relations", experience_years: 0 }
].freeze

candidates = CANDIDATE_DEFS.map do |def_|
  user = User.find_or_create_by!(email: def_[:email]) do |u|
    u.name = def_[:name]
    u.role = :candidate
    u.password = PASSWORD
  end

  Candidate.find_or_create_by!(user: user) do |c|
    c.headline = def_[:headline]
    c.skills = def_[:skills]
    c.experience_years = def_[:experience_years]
  end
end

# --- Jobs (50+, spread across companies/categories/cities/currencies) -------

CITIES = [ "Delhi, India", "Mumbai, India", "Bengaluru, India", "Hyderabad, India", "Chennai, India",
           "Kolkata, India", "Pune, India", "Ahmedabad, India", "Goa, India" ].freeze

TITLES_BY_CATEGORY = {
  pilot: [
    [ "First Officer - Airbus A320", "Seeking a qualified First Officer for our A320 fleet." ],
    [ "Captain - Boeing 737", "Type-rated Captain required for our B737 domestic fleet." ],
    [ "First Officer - ATR 72", "First Officer opening on our ATR 72 regional fleet." ],
    [ "Trainee Pilot - Cadet Program", "Cadet pilot program for CPL holders, type rating provided." ]
  ],
  cabin_crew: [
    [ "Cabin Crew - Domestic Routes", "Cabin crew for domestic short-haul routes." ],
    [ "Cabin Crew - International Routes", "Join our cabin crew team flying international long-haul routes." ],
    [ "Senior Flight Attendant", "Senior cabin crew role leading inflight service teams." ],
    [ "Inflight Service Supervisor", "Supervise cabin crew teams and inflight service standards." ]
  ],
  ame: [
    [ "Aircraft Maintenance Engineer", "Licensed AME required for line maintenance on narrow-body aircraft." ],
    [ "Line Maintenance Technician", "Technician for scheduled and unscheduled line maintenance." ],
    [ "Avionics Engineer", "Avionics specialist for fleet-wide systems maintenance." ],
    [ "Base Maintenance Engineer", "Base maintenance engineer for heavy checks and overhauls." ]
  ],
  mba: [
    [ "Assistant Manager - Airline Operations", "MBA graduate to join our operations management trainee program." ],
    [ "Revenue Management Analyst", "Analyst role optimizing fares and route profitability." ],
    [ "Strategy Associate", "Corporate strategy associate supporting network planning." ],
    [ "Airline Marketing Manager", "Manage brand and customer acquisition campaigns." ]
  ],
  ground_staff: [
    [ "Ground Staff - Passenger Services", "Front-line passenger services and check-in staff." ],
    [ "Ramp Agent", "Ramp operations agent handling aircraft turnaround." ],
    [ "Baggage Services Officer", "Manage baggage handling and lost-and-found operations." ],
    [ "Customer Service Executive", "Airport customer service and boarding gate executive." ]
  ]
}.freeze

SALARY_RANGES = {
  pilot: [ 1_200_000, 2_400_000 ],
  cabin_crew: [ 450_000, 850_000 ],
  ame: [ 700_000, 1_300_000 ],
  mba: [ 700_000, 1_500_000 ],
  ground_staff: [ 300_000, 600_000 ]
}.freeze

JOB_TYPES = %i[ full_time full_time full_time part_time contract seasonal ].freeze # weighted toward full_time

jobs_created = 0

COMPANY_DEFS.each do |company_def|
  company = Company.find_by!(name: company_def[:name])
  recruiter = recruiters_by_company.fetch(company_def[:name])
  is_gulf_based = company_def[:location].include?("UAE")

  TITLES_BY_CATEGORY.each do |category, title_defs|
    title_defs.each do |title, description|
      full_title = "#{title} - #{company.name}"
      location = is_gulf_based ? "Dubai, UAE" : CITIES.sample
      currency = is_gulf_based ? :aed : :inr
      min_salary, max_salary = SALARY_RANGES.fetch(category)
      min_salary, max_salary = (min_salary / 5), (max_salary / 5) if is_gulf_based # rough INR->AED scale for demo purposes

      # A handful of draft postings mixed in to prove Job.active filters them out.
      status = jobs_created % 11 == 0 ? :draft : :published

      Job.find_or_create_by!(title: full_title, company: company) do |j|
        j.recruiter = recruiter
        j.description = description
        j.location = location
        j.category = category
        j.job_type = JOB_TYPES.sample
        j.currency = currency
        j.salary_min = min_salary
        j.salary_max = max_salary
        j.status = status
        j.posted_at = rand(1..45).days.ago
      end

      jobs_created += 1
    end
  end
end

# A few extra IndiGo-specific postings so the "log in as recruiter@indigo.example"
# demo account has more than the shared pool to manage on its own dashboard.
[
  { title: "Senior Captain - Widebody Fleet", category: :pilot, location: "Delhi, India", salary_min: 2_000_000, salary_max: 3_200_000 },
  { title: "Cabin Crew - Weekend Batch", category: :cabin_crew, location: "Mumbai, India", salary_min: 480_000, salary_max: 780_000 }
].each do |attrs|
  Job.find_or_create_by!(title: attrs[:title], company: Company.find_by!(name: "IndiGo Airlines")) do |j|
    j.recruiter = indigo_recruiter
    j.description = "#{attrs[:title]} opening at IndiGo Airlines."
    j.location = attrs[:location]
    j.category = attrs[:category]
    j.job_type = :full_time
    j.currency = :inr
    j.salary_min = attrs[:salary_min]
    j.salary_max = attrs[:salary_max]
    j.status = :published
    j.posted_at = rand(1..10).days.ago
  end
end

# --- Applications: give the demo candidates and recruiters something to review ---

published_jobs = Job.active.to_a
application_statuses = %i[ submitted submitted under_review shortlisted rejected hired ] # weighted toward submitted/under_review

candidates.each do |candidate|
  published_jobs.sample(rand(3..6)).each do |job|
    Application.find_or_create_by!(job: job, candidate: candidate) do |a|
      a.status = application_statuses.sample
      a.cover_letter = "I'm very interested in the #{job.title} role at #{job.company.name} and believe my background is a strong fit."
      a.applied_at = rand(1..30).days.ago
    end
  end
end

puts "Seeded #{User.count} users, #{Company.count} companies, #{Candidate.count} candidates, " \
     "#{Job.count} jobs (#{Job.active.count} published), #{Application.count} applications."
