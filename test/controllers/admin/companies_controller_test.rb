require "test_helper"

class Admin::CompaniesControllerTest < ActionDispatch::IntegrationTest
  test "admin sees every company" do
    sign_in_as(users(:admin_one))
    get admin_companies_path
    assert_response :success
    assert_match companies(:indigo).name, response.body
  end

  test "non-admins cannot access the admin companies list" do
    sign_in_as(users(:candidate_one))
    get admin_companies_path
    assert_redirected_to root_path
  end
end
