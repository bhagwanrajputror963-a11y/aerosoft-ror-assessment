require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  test "valid with a user that has the candidate role" do
    candidate = Candidate.new(user: users(:candidate_two), headline: "Flight Engineer")
    assert candidate.valid?
  end

  test "invalid when the user does not have the candidate role" do
    candidate = Candidate.new(user: users(:recruiter_one))
    assert_not candidate.valid?
    assert_includes candidate.errors[:user], "must have the candidate role"
  end

  test "invalid with negative experience_years" do
    candidate = candidates(:arjun)
    candidate.experience_years = -1
    assert_not candidate.valid?
    assert_includes candidate.errors[:experience_years], "must be greater than or equal to 0"
  end

  test "jobs are reachable through applications" do
    assert_includes candidates(:arjun).jobs, jobs(:first_officer)
  end
end
