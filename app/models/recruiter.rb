class Recruiter < ApplicationRecord
  belongs_to :user
  belongs_to :company
  has_many :jobs, dependent: :restrict_with_error

  validates :position, presence: true
  validates :user_id, uniqueness: true
  validate :user_must_have_recruiter_role

  private

  def user_must_have_recruiter_role
    errors.add(:user, "must have the recruiter role") if user && !user.recruiter?
  end
end
