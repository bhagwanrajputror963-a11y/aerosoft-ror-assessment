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
    assert_response :unprocessable_entity
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
