class Candidate < ApplicationRecord
  belongs_to :user
  has_many :applications, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :jobs, through: :applications

  validates :user_id, uniqueness: true
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :resume_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validate :user_must_have_candidate_role

  private

  def user_must_have_candidate_role
    errors.add(:user, "must have the candidate role") if user && !user.candidate?
  end
end
