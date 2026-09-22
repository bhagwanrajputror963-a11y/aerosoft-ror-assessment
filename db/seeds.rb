# Idempotent demo data for Flying Crews.
# Run with: bin/rails db:seed

admin = User.find_or_create_by!(email: "admin@flyingcrews.com") do |u|
  u.name = "Site Admin"
  u.role = :admin
  u.password = "password123"
end

recruiter_user = User.find_or_create_by!(email: "recruiter@indigo.example") do |u|
  u.name = "Priya Sharma"
  u.role = :recruiter
  u.password = "password123"
end

company = Company.find_or_create_by!(name: "IndiGo Airlines") do |c|
  c.description = "India's largest passenger airline."
  c.website = "https://example.com"
  c.location = "Gurugram, India"
end

recruiter = Recruiter.find_or_create_by!(user: recruiter_user, company: company) do |r|
  r.position = "Talent Acquisition Lead"
end

candidate_user = User.find_or_create_by!(email: "candidate@example.com") do |u|
  u.name = "Arjun Mehta"
  u.role = :candidate
  u.password = "password123"
end

candidate = Candidate.find_or_create_by!(user: candidate_user) do |c|
  c.headline = "Commercial Pilot, 2500 flight hours"
  c.skills = "Boeing 737, Airbus A320, CRM"
  c.experience_years = 5
end

jobs = [
  {
    title: "First Officer - Airbus A320",
    description: "Seeking a qualified First Officer for our A320 fleet based in Delhi.",
    location: "Delhi, India",
    category: "Pilot",
    job_type: :full_time,
    salary_min: 1_200_000,
    salary_max: 2_000_000
  },
  {
    title: "Cabin Crew - International Routes",
    description: "Join our cabin crew team flying international long-haul routes.",
    location: "Mumbai, India",
    category: "Cabin Crew",
    job_type: :full_time,
    salary_min: 500_000,
    salary_max: 800_000
  },
  {
    title: "Aircraft Maintenance Engineer",
    description: "Licensed AME required for line maintenance on narrow-body aircraft.",
    location: "Bengaluru, India",
    category: "Ground Staff",
    job_type: :contract,
    salary_min: 700_000,
    salary_max: 1_100_000
  }
]

jobs.each do |attrs|
  Job.find_or_create_by!(title: attrs[:title], company: company) do |j|
    j.recruiter = recruiter
    j.description = attrs[:description]
    j.location = attrs[:location]
    j.category = attrs[:category]
    j.job_type = attrs[:job_type]
    j.salary_min = attrs[:salary_min]
    j.salary_max = attrs[:salary_max]
    j.status = :published
    j.posted_at = Time.current
  end
end

puts "Seeded #{User.count} users, #{Company.count} companies, #{Job.count} jobs."
