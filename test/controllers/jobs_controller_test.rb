require "test_helper"

class JobsControllerTest < ActionDispatch::IntegrationTest
  test "index lists published jobs without requiring login" do
    get jobs_path
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
    assert_no_match jobs(:draft_job).title, response.body
  end

  test "index filters by query params" do
    get jobs_path, params: { location: "Mumbai" }
    assert_match jobs(:cabin_crew).title, response.body
    assert_no_match jobs(:first_officer).title, response.body
  end

  test "index filters case-insensitively, matching what the live-search JS sends on keyup" do
    get jobs_path, params: { location: "delhi" }
    assert_match jobs(:first_officer).title, response.body
    assert_no_match jobs(:cabin_crew).title, response.body
  end

  test "a turbo-frame-scoped request (what live search actually issues) still returns filtered results" do
    get jobs_path, params: { q: "cabin" }, headers: { "Turbo-Frame" => "jobs_results" }
    assert_response :success
    assert_match jobs(:cabin_crew).title, response.body
    assert_no_match jobs(:first_officer).title, response.body
    assert_match '<turbo-frame id="jobs_results"', response.body
  end

  test "index paginates and renders real pagination markup, not HTML-escaped text" do
    # Pagy's nav helpers return a plain (unmarked) HTML string by design, not
    # an html_safe SafeBuffer — <%= %> would escape it into literal
    # "&lt;nav...&gt;" text on the page. Needs <%== %> (raw output) instead.
    13.times { |n| create_published_job("Extra Job #{n}") }

    get jobs_path
    assert_response :success
    assert_match '<nav class="pagy-bootstrap nav"', response.body
    assert_no_match "&lt;nav", response.body
    assert_match 'href="/jobs?page=2"', response.body
  end

  test "show displays a single job" do
    get job_path(jobs(:first_officer))
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
  end

  test "recruiter can post a new job" do
    sign_in_as(users(:recruiter_one))
    assert_difference("Job.count", 1) do
      post jobs_path, params: {
        job: {
          title: "Ground Ops Supervisor", description: "Manage ground operations.",
          location: "Delhi, India", category: "ground_staff", job_type: "full_time",
          status: "published", currency: "inr", salary_min: 600_000, salary_max: 900_000
        }
      }
    end
    assert_redirected_to job_path(Job.last)
    assert_equal recruiters(:priya).company, Job.last.company
    assert Job.last.inr?
  end

  test "candidate cannot post a new job" do
    sign_in_as(users(:candidate_one))
    assert_no_difference("Job.count") do
      post jobs_path, params: {
        job: { title: "Nope", description: "x", location: "x", job_type: "full_time", status: "published" }
      }
    end
    assert_redirected_to root_path
  end

  test "anonymous users cannot post a job" do
    assert_no_difference("Job.count") do
      post jobs_path, params: { job: { title: "Nope" } }
    end
    assert_redirected_to login_path
  end

  test "recruiter can update their own job" do
    sign_in_as(users(:recruiter_one))
    patch job_path(jobs(:first_officer)), params: { job: { title: "Senior First Officer" } }
    assert_redirected_to job_path(jobs(:first_officer))
    assert_equal "Senior First Officer", jobs(:first_officer).reload.title
  end

  test "recruiter cannot update a job they do not own" do
    other_recruiter = User.create!(name: "Other Recruiter", email: "other@example.com", password: "password123", role: :recruiter)
    other_company = Company.create!(name: "SpiceJet")
    Recruiter.create!(user: other_recruiter, company: other_company, position: "Lead")

    sign_in_as(other_recruiter)
    patch job_path(jobs(:first_officer)), params: { job: { title: "Hijacked" } }
    assert_redirected_to jobs_path
    assert_not_equal "Hijacked", jobs(:first_officer).reload.title
  end

  test "recruiter can delete their own job" do
    sign_in_as(users(:recruiter_one))
    assert_difference("Job.count", -1) do
      delete job_path(jobs(:cabin_crew))
    end
  end

  test "job card fragment cache invalidates when the job changes" do
    with_fragment_caching do
      job = jobs(:first_officer)

      get jobs_path
      assert_match job.title, response.body

      job.update!(title: "Captain - Airbus A320")

      get jobs_path
      assert_match "Captain - Airbus A320", response.body
      assert_no_match "First Officer - Airbus A320", response.body
    end
  end

  test "job card fragment cache invalidates when the company changes (touch: true)" do
    with_fragment_caching do
      get jobs_path
      assert_match companies(:indigo).name, response.body

      companies(:indigo).update!(name: "Renamed Airlines")

      get jobs_path
      assert_match "Renamed Airlines", response.body
    end
  end

  private

  def create_published_job(title)
    recruiters(:priya).jobs.create!(
      company: companies(:indigo), title: title, description: "x", location: "Delhi, India",
      category: :ground_staff, job_type: :full_time, status: :published, posted_at: Time.current
    )
  end
end
