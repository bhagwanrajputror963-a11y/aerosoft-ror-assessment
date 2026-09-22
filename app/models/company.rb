class Company < ApplicationRecord
  # Order matters: jobs must be destroyed before recruiters, since a job
  # requires a recruiter_id (NOT NULL) and cannot be nullified out from under it.
  has_many :jobs, dependent: :destroy
  has_many :recruiters, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
end
