require "test_helper"

class ApplicationTest < ActiveSupport::TestCase
  test "valid with a job and a candidate who has not applied yet" do
    application = Application.new(job: jobs(:cabin_crew), candidate: candidates(:rina), cover_letter: "Interested!")
    assert application.valid?
  end

  test "invalid when the candidate has already applied to the job" do
    application = Application.new(job: jobs(:first_officer), candidate: candidates(:arjun))
    assert_not application.valid?
    assert_includes application.errors[:candidate_id], "has already applied to this job"
  end

  test "defaults status to submitted and applied_at to now" do
    application = Application.create!(job: jobs(:cabin_crew), candidate: candidates(:rina))
    assert application.submitted?
    assert_in_delta Time.current, application.applied_at, 5.seconds
  end

  test "recent scope only returns applications from the last 30 days" do
    old_application = Application.create!(
      job: jobs(:cabin_crew), candidate: candidates(:rina),
      created_at: 40.days.ago, applied_at: 40.days.ago
    )
    assert_includes Application.recent, applications(:arjun_applies_first_officer)
    assert_not_includes Application.recent, old_application
  end

  test "status enum exposes predicate methods" do
    application = applications(:arjun_applies_first_officer)
    application.update!(status: :shortlisted)
    assert application.shortlisted?
  end

  test "moving an application to hired closes the job" do
    application = applications(:arjun_applies_first_officer)
    assert application.job.published?

    application.update!(status: :hired)

    assert application.job.reload.closed?
  end

  test "moving an application to any other status does not close the job" do
    application = applications(:arjun_applies_first_officer)

    application.update!(status: :shortlisted)

    assert application.job.reload.published?
  end

  test "hiring for an already-closed job does not error" do
    application = applications(:arjun_applies_first_officer)
    application.job.update!(status: :closed)

    assert_nothing_raised { application.update!(status: :hired) }
    assert application.job.reload.closed?
  end

  test "invalid to apply to a job that is not published" do
    application = Application.new(job: jobs(:draft_job), candidate: candidates(:rina))

    assert_not application.valid?
    assert_includes application.errors[:job], "is not accepting applications"
  end

  test "existing application is unaffected when the job later closes" do
    # on: :create only — an application already on file for a job must
    # survive that job closing (e.g. because someone else got hired).
    application = applications(:arjun_applies_first_officer)
    application.job.update!(status: :closed)

    assert application.reload.valid?
  end
end
