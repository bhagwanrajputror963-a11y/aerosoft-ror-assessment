require "test_helper"

class RecruiterTest < ActiveSupport::TestCase
  test "valid with a user that has the recruiter role" do
    recruiter = Recruiter.new(user: users(:recruiter_one), company: companies(:indigo), position: "HR Manager")
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
end
