class Application < ApplicationRecord
  belongs_to :job
  belongs_to :candidate

  enum :status, { submitted: 0, under_review: 1, shortlisted: 2, rejected: 3, hired: 4 }

  validates :candidate_id, uniqueness: { scope: :job_id, message: "has already applied to this job" }
  validate :job_must_be_open, on: :create

  before_validation { self.status ||= :submitted }
  before_validation { self.applied_at ||= Time.current }
  after_save :close_job_if_hired

  scope :recent, -> { where("created_at >= ?", 30.days.ago) }

  private

  def job_must_be_open
    errors.add(:job, "is not accepting applications") if job && !job.published?
  end

  # A job represents one opening; once someone is hired for it, it should
  # stop accepting/showing further applicants rather than staying listed
  # indefinitely alongside a filled position.
  def close_job_if_hired
    return unless saved_change_to_status? && hired?

    job.update!(status: :closed) unless job.closed?
  end
end
