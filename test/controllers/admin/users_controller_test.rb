require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin sees every user with role-specific details" do
    sign_in_as(users(:admin_one))
    get admin_users_path
    assert_response :success
    assert_match users(:recruiter_one).email, response.body
    assert_match users(:candidate_one).email, response.body
    assert_match candidates(:arjun).headline, response.body
  end

  test "non-admins cannot access the admin users list" do
    sign_in_as(users(:recruiter_one))
    get admin_users_path
    assert_redirected_to root_path
  end
end
