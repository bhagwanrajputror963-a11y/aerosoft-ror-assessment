require "test_helper"

class JobsControllerTest < ActionDispatch::IntegrationTest
  test "index lists published jobs without requiring login" do
    get jobs_path
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
    assert_no_match jobs(:draft_job).title, response.body
  end

  test "index shows an applied badge on jobs the current candidate has applied to, not others" do
    sign_in_as(users(:candidate_one)) # candidate_one already applied to first_officer via fixtures
    get jobs_path
    within_job_card(jobs(:first_officer)) { |html| assert_match "Applied", html }
    within_job_card(jobs(:cabin_crew)) { |html| assert_no_match "Applied", html }
  end

  test "index shows no applied badge for a candidate who hasn't applied to anything" do
    sign_in_as(users(:candidate_two))
    get jobs_path
    assert_no_match "Applied", response.body
  end

  test "index shows no applied badge for anonymous visitors" do
    get jobs_path
    assert_no_match "Applied", response.body
  end

  test "the job-card fragment cache does not leak one candidate's applied status onto another candidate's view" do
    # jobs/_job_card caches the shared markup per [job, job.company], but the
    # applied-status badge must render fresh per request — otherwise whichever
    # candidate's view populates the cache first "wins" for every later viewer.
    with_fragment_caching do
      sign_in_as(users(:candidate_one)) # has applied to first_officer
      get jobs_path
      within_job_card(jobs(:first_officer)) { |html| assert_match "Applied", html }

      delete logout_path
      sign_in_as(users(:candidate_two)) # has NOT applied to first_officer
      get jobs_path
      within_job_card(jobs(:first_officer)) { |html| assert_no_match "Applied", html }
    end
  end

  test "job title links break out of the search-results turbo frame" do
    # Job cards render inside turbo_frame_tag("jobs_results") for live search.
    # Without data-turbo-frame="_top" on the title link, clicking a job from
    # the board scopes navigation to that frame — but jobs/show has no
    # matching <turbo-frame id="jobs_results">, so Turbo shows "Content
    # missing" instead of the job page. This only reproduces in a real
    # browser (Turbo is client-side JS); this test locks down the
    # server-side half of the fix: the attribute itself must be present.
    get jobs_path
    assert_select %(a[href="#{job_path(jobs(:first_officer))}"][data-turbo-frame="_top"])
  end

  test "the Clear link forces a hard navigation, not a Turbo-managed one" do
    # data-turbo-frame="_top" (the first fix attempt) was reported to still
    # not reset the search form's inputs/selects. Since Turbo Frame behavior
    # is client-side JS this environment has no browser to verify, disable
    # Turbo outright for this link instead: a real full page load can't be
    # scoped to a frame by any client-side logic, because Turbo never
    # intercepts the click in the first place.
    get jobs_path
    assert_select %(a[href="#{jobs_path}"][data-turbo="false"])
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

  test "show displays the company's description when present" do
    get job_path(jobs(:first_officer))
    assert_match companies(:indigo).description, response.body
  end

  test "show omits the about-company section when the company has no description" do
    companies(:indigo).update!(description: nil)
    get job_path(jobs(:first_officer))
    assert_no_match "About #{companies(:indigo).name}", response.body
  end

  test "show offers Apply now to a candidate who has not applied yet" do
    sign_in_as(users(:candidate_two))
    get job_path(jobs(:first_officer))
    assert_match "Apply now", response.body
    assert_no_match "You applied", response.body
  end

  test "show shows applied status instead of Apply now to a candidate who already applied" do
    sign_in_as(users(:candidate_one)) # candidate_one already applied to first_officer via fixtures
    get job_path(jobs(:first_officer))
    assert_match "You applied", response.body
    assert_match applications(:arjun_applies_first_officer).status.titleize, response.body
    assert_no_match "Apply now", response.body
  end

  test "show still displays applied status after the job closes (e.g. someone else got hired)" do
    applications(:arjun_applies_first_officer).job.update!(status: :closed)
    sign_in_as(users(:candidate_one))

    get job_path(jobs(:first_officer))
    assert_match "You applied", response.body
    assert_no_match "Apply now", response.body
    assert_no_match "no longer accepting applications", response.body
  end

  test "show hides Apply now and shows a closed message for a candidate who never applied" do
    jobs(:cabin_crew).update!(status: :closed)
    sign_in_as(users(:candidate_two)) # has not applied to cabin_crew

    get job_path(jobs(:cabin_crew))
    assert_no_match "Apply now", response.body
    assert_match "no longer accepting applications", response.body
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

  test "admin can edit and delete any job, not just ones they posted" do
    sign_in_as(users(:admin_one))

    patch job_path(jobs(:first_officer)), params: { job: { title: "Admin-edited title" } }
    assert_redirected_to job_path(jobs(:first_officer))
    assert_equal "Admin-edited title", jobs(:first_officer).reload.title

    assert_difference("Job.count", -1) do
      delete job_path(jobs(:cabin_crew))
    end
  end

  test "admin sees Edit/Delete actions on a job page even though they didn't post it" do
    sign_in_as(users(:admin_one))
    get job_path(jobs(:first_officer))
    assert_select %(a[href="#{edit_job_path(jobs(:first_officer))}"])
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
