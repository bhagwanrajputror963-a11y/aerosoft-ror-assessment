require "test_helper"

class JobTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    job = Job.new(
      company: companies(:indigo), recruiter: recruiters(:priya),
      title: "Flight Dispatcher", description: "Plan and monitor flights.",
      location: "Delhi, India", job_type: :full_time, status: :published
    )
    assert job.valid?
  end

  test "invalid without title, description or location" do
    job = Job.new(company: companies(:indigo), recruiter: recruiters(:priya))
    assert_not job.valid?
    assert_includes job.errors[:title], "can't be blank"
    assert_includes job.errors[:description], "can't be blank"
    assert_includes job.errors[:location], "can't be blank"
  end

  test "invalid when salary_max is less than salary_min" do
    job = jobs(:first_officer)
    job.salary_min = 1_000_000
    job.salary_max = 500_000
    assert_not job.valid?
    assert_includes job.errors[:salary_max], "must be greater than or equal to salary_min"
  end

  test "active scope only returns published jobs" do
    assert_includes Job.active, jobs(:first_officer)
    assert_not_includes Job.active, jobs(:draft_job)
  end

  test "filter searches by title, location, category, type and minimum salary" do
    results = Job.filter(q: "First Officer")
    assert_includes results, jobs(:first_officer)
    assert_not_includes results, jobs(:cabin_crew)

    results = Job.filter(location: "Mumbai")
    assert_includes results, jobs(:cabin_crew)
    assert_not_includes results, jobs(:first_officer)

    results = Job.filter(category: "Pilot")
    assert_includes results, jobs(:first_officer)
    assert_not_includes results, jobs(:cabin_crew)

    results = Job.filter(min_salary: 1_000_000)
    assert_includes results, jobs(:first_officer)
    assert_not_includes results, jobs(:cabin_crew)
  end

  test "filter never returns draft or closed jobs" do
    assert_not_includes Job.filter({}), jobs(:draft_job)
  end
end
