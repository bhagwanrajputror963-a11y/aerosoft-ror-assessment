require "test_helper"

class CandidateProfilesControllerTest < ActionDispatch::IntegrationTest
  test "candidate can view their own edit form" do
    sign_in_as(users(:candidate_one))
    get edit_candidate_profile_path
    assert_response :success
    assert_match candidates(:arjun).headline, response.body
  end

  test "candidate can update their own profile" do
    sign_in_as(users(:candidate_one))
    patch candidate_profile_path, params: {
      candidate: { headline: "Senior First Officer", skills: "A320, B737", experience_years: 6, resume_url: "https://example.com/cv.pdf" }
    }
    assert_redirected_to dashboard_path

    candidates(:arjun).reload
    assert_equal "Senior First Officer", candidates(:arjun).headline
    assert_equal "A320, B737", candidates(:arjun).skills
    assert_equal 6, candidates(:arjun).experience_years
    assert_equal "https://example.com/cv.pdf", candidates(:arjun).resume_url
  end

  test "invalid profile update re-renders the form with errors" do
    sign_in_as(users(:candidate_one))
    patch candidate_profile_path, params: { candidate: { experience_years: -1 } }
    assert_response :unprocessable_entity
    assert_match "must be greater than or equal to 0", response.body
  end

  test "recruiter cannot access the candidate profile form" do
    sign_in_as(users(:recruiter_one))
    get edit_candidate_profile_path
    assert_redirected_to root_path
  end

  test "anonymous visitor is redirected to log in" do
    get edit_candidate_profile_path
    assert_redirected_to login_path
  end
end
