require "test_helper"

class ApplicationsControllerTest < ActionDispatch::IntegrationTest
  test "candidate can apply to a job they have not applied to yet" do
    sign_in_as(users(:candidate_two))
    assert_difference("Application.count", 1) do
      post job_applications_path(jobs(:first_officer)), params: { application: { cover_letter: "I'm interested." } }
    end
    assert_redirected_to dashboard_path
  end

  test "candidate cannot apply twice to the same job" do
    sign_in_as(users(:candidate_one))
    assert_no_difference("Application.count") do
      post job_applications_path(jobs(:first_officer)), params: { application: { cover_letter: "Again!" } }
    end
    assert_redirected_to job_path(jobs(:first_officer))
  end

  test "candidate who already applied is redirected away from the apply form, not shown it" do
    sign_in_as(users(:candidate_one))
    get new_job_application_path(jobs(:first_officer))
    assert_redirected_to job_path(jobs(:first_officer))
  end

  test "candidate cannot apply to a closed job, redirected instead of shown the form" do
    jobs(:cabin_crew).update!(status: :closed)
    sign_in_as(users(:candidate_two))

    get new_job_application_path(jobs(:cabin_crew))
    assert_redirected_to job_path(jobs(:cabin_crew))

    assert_no_difference("Application.count") do
      post job_applications_path(jobs(:cabin_crew)), params: { application: { cover_letter: "x" } }
    end
  end

  test "recruiter marking an applicant as hired closes the job for further applicants" do
    sign_in_as(users(:recruiter_one))
    application = applications(:arjun_applies_first_officer)

    patch update_status_application_path(application), params: { status: "hired" }

    assert application.job.reload.closed?

    sign_in_as(users(:candidate_two))
    assert_no_difference("Application.count") do
      post job_applications_path(jobs(:first_officer)), params: { application: { cover_letter: "x" } }
    end
  end

  test "recruiter cannot apply to a job" do
    sign_in_as(users(:recruiter_one))
    assert_no_difference("Application.count") do
      post job_applications_path(jobs(:cabin_crew)), params: { application: { cover_letter: "x" } }
    end
    assert_redirected_to root_path
  end

  test "anonymous users are redirected to log in before applying" do
    assert_no_difference("Application.count") do
      post job_applications_path(jobs(:cabin_crew)), params: { application: { cover_letter: "x" } }
    end
    assert_redirected_to login_path
  end

  test "recruiter can update the status of an application on their job" do
    sign_in_as(users(:recruiter_one))
    application = applications(:arjun_applies_first_officer)
    patch update_status_application_path(application), params: { status: "shortlisted" }
    assert_redirected_to dashboard_path
    assert application.reload.shortlisted?
  end

  test "admin can update the status of any application, regardless of company" do
    sign_in_as(users(:admin_one))
    application = applications(:arjun_applies_first_officer)
    patch update_status_application_path(application), params: { status: "shortlisted" }
    assert_redirected_to admin_applications_path
    assert application.reload.shortlisted?
  end

  test "a recruiter from another company cannot update the application status" do
    other_recruiter = User.create!(name: "Other Recruiter", email: "other@example.com", password: "password123", role: :recruiter)
    other_company = Company.create!(name: "SpiceJet")
    Recruiter.create!(user: other_recruiter, company: other_company, position: "Lead")

    sign_in_as(other_recruiter)
    application = applications(:arjun_applies_first_officer)
    patch update_status_application_path(application), params: { status: "shortlisted" }
    assert_redirected_to dashboard_path
    assert_not application.reload.shortlisted?
  end
end
