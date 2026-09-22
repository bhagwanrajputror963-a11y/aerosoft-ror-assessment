class User < ApplicationRecord
  has_secure_password

  enum :role, { candidate: 0, recruiter: 1, admin: 2 }

  has_one :candidate, dependent: :destroy
  has_one :recruiter, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  before_validation { self.email = email.strip.downcase if email.present? }
end
