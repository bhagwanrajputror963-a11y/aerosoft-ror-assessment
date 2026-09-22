class Job < ApplicationRecord
  belongs_to :company
  belongs_to :recruiter
  has_many :applications, dependent: :destroy
  has_many :candidates, through: :applications

  enum :job_type, { full_time: 0, part_time: 1, contract: 2, seasonal: 3 }
  enum :status, { draft: 0, published: 1, closed: 2 }
  # Matches flying-crews.com's five listed job categories.
  enum :category, { pilot: 0, cabin_crew: 1, ame: 2, mba: 3, ground_staff: 4 }

  CATEGORY_LABELS = {
    "pilot" => "Pilot", "cabin_crew" => "Cabin Crew", "ame" => "AME (Aircraft Maintenance Engineer)",
    "mba" => "MBA / Management", "ground_staff" => "Ground Staff"
  }.freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :location, presence: true
  validates :category, presence: true
  validates :salary_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :salary_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :salary_range_valid

  scope :active, -> { where(status: :published) }
  scope :search_title, ->(q) { where("title LIKE :q", q: "%#{sanitize_sql_like(q)}%") if q.present? }
  scope :in_location, ->(loc) { where("location LIKE :q", q: "%#{sanitize_sql_like(loc)}%") if loc.present? }
  scope :in_category, ->(cat) { where(category: cat) if cat.present? }
  scope :of_type, ->(type) { where(job_type: type) if type.present? }
  scope :salary_at_least, ->(amount) { where("salary_max >= ?", amount) if amount.present? }
  scope :recent_first, -> { order(posted_at: :desc) }

  def self.filter(params)
    active
      .search_title(params[:q])
      .in_location(params[:location])
      .in_category(params[:category])
      .of_type(params[:job_type])
      .salary_at_least(params[:min_salary])
      .recent_first
  end

  private

  def salary_range_valid
    return if salary_min.blank? || salary_max.blank?
    errors.add(:salary_max, "must be greater than or equal to salary_min") if salary_max < salary_min
  end
end
