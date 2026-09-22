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
          status: "published", salary_min: 600_000, salary_max: 900_000
        }
      }
    end
    assert_redirected_to job_path(Job.last)
    assert_equal recruiters(:priya).company, Job.last.company
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
end
