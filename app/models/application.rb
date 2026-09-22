class Application < ApplicationRecord
  belongs_to :job
  belongs_to :candidate

  enum :status, { submitted: 0, under_review: 1, shortlisted: 2, rejected: 3, hired: 4 }

  validates :candidate_id, uniqueness: { scope: :job_id, message: "has already applied to this job" }

  before_validation { self.status ||= :submitted }
  before_validation { self.applied_at ||= Time.current }

  scope :recent, -> { where("created_at >= ?", 30.days.ago) }
end
