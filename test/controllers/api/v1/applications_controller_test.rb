require "test_helper"

class Api::V1::ApplicationsControllerTest < ActionDispatch::IntegrationTest
  test "authenticated candidate can apply via the API" do
    sign_in_as(users(:candidate_two))
    assert_difference("Application.count", 1) do
      post api_v1_applications_path, params: { job_id: jobs(:cabin_crew).id, cover_letter: "Via API" }
    end
    assert_response :created
  end

  test "unauthenticated requests are rejected" do
    assert_no_difference("Application.count") do
      post api_v1_applications_path, params: { job_id: jobs(:cabin_crew).id }
    end
    assert_response :unauthorized
  end

  test "recruiters cannot apply via the API" do
    sign_in_as(users(:recruiter_one))
    assert_no_difference("Application.count") do
      post api_v1_applications_path, params: { job_id: jobs(:cabin_crew).id }
    end
    assert_response :forbidden
  end

  test "returns validation errors as JSON for a duplicate application" do
    sign_in_as(users(:candidate_one))
    assert_no_difference("Application.count") do
      post api_v1_applications_path, params: { job_id: jobs(:first_officer).id }
    end
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].join, "already applied"
  end
end
