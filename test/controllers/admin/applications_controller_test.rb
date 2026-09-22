require "test_helper"

class Admin::ApplicationsControllerTest < ActionDispatch::IntegrationTest
  test "admin sees every application across every company" do
    sign_in_as(users(:admin_one))
    get admin_applications_path
    assert_response :success
    assert_match candidates(:arjun).user.name, response.body
    assert_match jobs(:first_officer).title, response.body
  end

  test "non-admins cannot access the admin applications list" do
    sign_in_as(users(:recruiter_one))
    get admin_applications_path
    assert_redirected_to root_path
  end
end
