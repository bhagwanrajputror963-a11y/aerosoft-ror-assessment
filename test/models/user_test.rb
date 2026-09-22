require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with name, email, password and role" do
    user = User.new(name: "New User", email: "new@example.com", password: "password123", role: :candidate)
    assert user.valid?
  end

  test "invalid without a name" do
    user = User.new(email: "noname@example.com", password: "password123", role: :candidate)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "invalid without a valid email format" do
    user = User.new(name: "Bad Email", email: "not-an-email", password: "password123", role: :candidate)
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "invalid with a duplicate email regardless of case" do
    duplicate = User.new(name: "Dup", email: users(:candidate_one).email.upcase, password: "password123", role: :candidate)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "downcases email before validation" do
    user = User.create!(name: "Mixed Case", email: "MixedCase@Example.com", password: "password123", role: :candidate)
    assert_equal "mixedcase@example.com", user.email
  end

  test "authenticates with the correct password" do
    user = users(:candidate_one)
    assert user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end

  test "role enum exposes predicate methods" do
    assert users(:candidate_one).candidate?
    assert users(:recruiter_one).recruiter?
    assert users(:admin_one).admin?
  end
end
