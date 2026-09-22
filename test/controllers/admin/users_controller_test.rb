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

  test "users are listed most recently joined first" do
    # Same role (so role doesn't confound the comparison) but names that sort
    # the OPPOSITE way from creation order, so this can't pass by accident
    # against an order(:role, :name) implementation.
    older = User.create!(name: "Aaa Older", email: "aaa-older@example.com", password: "password123", role: :candidate, created_at: 2.days.ago)
    newer = User.create!(name: "Zzz Newer", email: "zzz-newer@example.com", password: "password123", role: :candidate, created_at: 1.minute.ago)

    sign_in_as(users(:admin_one))
    get admin_users_path

    assert_operator response.body.index(newer.email), :<, response.body.index(older.email),
      "expected the more recently joined user to appear before the older one"
  end

  test "non-admins cannot access the admin users list" do
    sign_in_as(users(:recruiter_one))
    get admin_users_path
    assert_redirected_to root_path
  end
end
