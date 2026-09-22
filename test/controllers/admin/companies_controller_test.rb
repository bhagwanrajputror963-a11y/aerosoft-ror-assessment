require "test_helper"

class Admin::CompaniesControllerTest < ActionDispatch::IntegrationTest
  test "admin sees every company" do
    sign_in_as(users(:admin_one))
    get admin_companies_path
    assert_response :success
    assert_match companies(:indigo).name, response.body
  end

  test "companies are listed most recently added first" do
    # Names deliberately sort the OPPOSITE way alphabetically, so this can't
    # pass by accident against an order(:name) implementation.
    older = Company.create!(name: "Aaa Airlines", created_at: 2.days.ago)
    newer = Company.create!(name: "Zzz Airlines", created_at: 1.minute.ago)

    sign_in_as(users(:admin_one))
    get admin_companies_path

    assert_operator response.body.index(newer.name), :<, response.body.index(older.name),
      "expected the more recently created company to appear before the older one"
  end

  test "non-admins cannot access the admin companies list" do
    sign_in_as(users(:candidate_one))
    get admin_companies_path
    assert_redirected_to root_path
  end
end
