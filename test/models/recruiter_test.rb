require "test_helper"

class RecruiterTest < ActiveSupport::TestCase
  test "valid with a user that has the recruiter role and no existing profile" do
    user = User.create!(name: "New Recruiter", email: "newrec@example.com", password: "password123", role: :recruiter)
    recruiter = Recruiter.new(user: user, company: companies(:indigo), position: "HR Manager")
    assert recruiter.valid?
  end

  test "invalid without a position" do
    recruiter = Recruiter.new(user: users(:recruiter_one), company: companies(:indigo))
    assert_not recruiter.valid?
    assert_includes recruiter.errors[:position], "can't be blank"
  end

  test "invalid when the user does not have the recruiter role" do
    recruiter = Recruiter.new(user: users(:candidate_one), company: companies(:indigo), position: "HR Manager")
    assert_not recruiter.valid?
    assert_includes recruiter.errors[:user], "must have the recruiter role"
  end

  test "invalid when the user already has a recruiter profile" do
    recruiter = Recruiter.new(user: recruiters(:priya).user, company: companies(:indigo), position: "Another Role")
    assert_not recruiter.valid?
    assert_includes recruiter.errors[:user_id], "has already been taken"
  end
end
