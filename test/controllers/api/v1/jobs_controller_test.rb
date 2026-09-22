require "test_helper"

class Api::V1::JobsControllerTest < ActionDispatch::IntegrationTest
  test "index returns published jobs as JSON" do
    get api_v1_jobs_path
    assert_response :success
    body = JSON.parse(response.body)
    titles = body.map { |j| j["title"] }
    assert_includes titles, jobs(:first_officer).title
    assert_not_includes titles, jobs(:draft_job).title
    assert_equal companies(:indigo).name, body.first["company"]["name"]
  end

  test "index applies search filters" do
    get api_v1_jobs_path, params: { category: "pilot" }
    body = JSON.parse(response.body)
    assert_not_empty body
    assert(body.all? { |j| j["category"] == "pilot" })
  end

  test "show returns a single job with its company" do
    get api_v1_job_path(jobs(:first_officer))
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal jobs(:first_officer).title, body["title"]
    assert_equal jobs(:first_officer).currency, body["currency"]
    assert_equal companies(:indigo).website, body["company"]["website"]
  end

  test "show returns 404 for a missing job" do
    get api_v1_job_path(id: 0)
    assert_response :not_found
  end
end
