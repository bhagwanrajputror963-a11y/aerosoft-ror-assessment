require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "valid with a unique name" do
    company = Company.new(name: "Vistara Airlines")
    assert company.valid?
  end

  test "invalid without a name" do
    company = Company.new
    assert_not company.valid?
    assert_includes company.errors[:name], "can't be blank"
  end

  test "invalid with a duplicate name" do
    company = Company.new(name: companies(:indigo).name)
    assert_not company.valid?
    assert_includes company.errors[:name], "has already been taken"
  end

  test "invalid with a malformed website" do
    company = Company.new(name: "Bad Site Co", website: "not a url")
    assert_not company.valid?
    assert_includes company.errors[:website], "is invalid"
  end

  test "destroying a company destroys its jobs" do
    company = companies(:indigo)
    assert_difference("Job.count", -company.jobs.count) do
      company.destroy
    end
  end
end
