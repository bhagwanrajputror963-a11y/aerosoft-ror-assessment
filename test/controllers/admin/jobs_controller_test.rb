require "test_helper"

class Admin::JobsControllerTest < ActionDispatch::IntegrationTest
  test "admin sees every job regardless of status or company" do
    sign_in_as(users(:admin_one))
    get admin_jobs_path
    assert_response :success
    assert_match jobs(:first_officer).title, response.body
    assert_match jobs(:draft_job).title, response.body # not published — still visible to admin
  end

  test "recruiter cannot access the admin jobs list" do
    sign_in_as(users(:recruiter_one))
    get admin_jobs_path
    assert_redirected_to root_path
  end

  test "candidate cannot access the admin jobs list" do
    sign_in_as(users(:candidate_one))
    get admin_jobs_path
    assert_redirected_to root_path
  end

  test "anonymous visitor is redirected to log in" do
    get admin_jobs_path
    assert_redirected_to login_path
  end
end
