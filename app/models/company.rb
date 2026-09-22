class Company < ApplicationRecord
  has_many :recruiters, dependent: :destroy
  has_many :jobs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
end
