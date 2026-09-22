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

  test "admin dashboard shows platform-wide counts" do
    sign_in_as(users(:admin_one))
    get dashboard_path
    assert_response :success
    assert_match Job.count.to_s, response.body
  end
end
