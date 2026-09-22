require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "logs in with valid credentials and redirects to dashboard" do
    sign_in_as(users(:candidate_one))
    assert_redirected_to dashboard_path
  end

  test "rejects invalid credentials" do
    post login_path, params: { email: users(:candidate_one).email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_match "Invalid email or password", response.body
  end

  test "logs out and clears the session" do
    sign_in_as(users(:candidate_one))
    delete logout_path
    assert_redirected_to root_path
    get dashboard_path
    assert_redirected_to login_path
  end
end
