class Candidate < ApplicationRecord
  belongs_to :user
  has_many :applications, dependent: :destroy
  has_many :jobs, through: :applications

  validates :user_id, uniqueness: true
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :user_must_have_candidate_role

  private

  def user_must_have_candidate_role
    errors.add(:user, "must have the candidate role") if user && !user.candidate?
  end
end
