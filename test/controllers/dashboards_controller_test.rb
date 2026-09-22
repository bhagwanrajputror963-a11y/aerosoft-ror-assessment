require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "redirects anonymous users to log in" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "candidate dashboard lists their applications" do
    sign_in_as(users(:candidate_one))
    get dashboard_path
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
  end

  test "recruiter dashboard lists their job postings and applicants" do
    sign_in_as(users(:recruiter_one))
    get dashboard_path
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
    assert_match candidates(:arjun).user.name, response.body
  end

  test "applicants on a job are listed most recently applied first" do
    # Inserted in the OPPOSITE order from their created_at timestamps, so
    # this can't pass by accident against a plain (insertion-order) query —
    # only an explicit order(created_at: :desc) produces "Arjun then Rina".
    Application.create!(job: jobs(:cabin_crew), candidate: candidates(:rina), created_at: 2.days.ago)
    Application.create!(job: jobs(:cabin_crew), candidate: candidates(:arjun), created_at: 1.minute.ago)

    sign_in_as(users(:recruiter_one))
    get dashboard_path

    assert_operator response.body.index(candidates(:arjun).user.name), :<, response.body.index(candidates(:rina).user.name),
      "expected the more recently applied candidate to appear before the older applicant"
  end

  test "admin dashboard shows platform-wide counts" do
    sign_in_as(users(:admin_one))
    get dashboard_path
    assert_response :success
    assert_match Job.count.to_s, response.body
  end
end
