class Job < ApplicationRecord
  belongs_to :company
  belongs_to :recruiter
  has_many :applications, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :candidates, through: :applications

  enum :job_type, { full_time: 0, part_time: 1, contract: 2, seasonal: 3 }
  enum :status, { draft: 0, published: 1, closed: 2 }
  # Matches flying-crews.com's five listed job categories.
  enum :category, { pilot: 0, cabin_crew: 1, ame: 2, mba: 3, ground_staff: 4 }
  enum :currency, { inr: 0, usd: 1, eur: 2, gbp: 3, aed: 4 }

  CATEGORY_LABELS = {
    "pilot" => "Pilot", "cabin_crew" => "Cabin Crew", "ame" => "AME (Aircraft Maintenance Engineer)",
    "mba" => "MBA / Management", "ground_staff" => "Ground Staff"
  }.freeze

  CURRENCY_SYMBOLS = { "inr" => "₹", "usd" => "$", "eur" => "€", "gbp" => "£", "aed" => "AED " }.freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :location, presence: true
  validates :category, presence: true
  validates :currency, presence: true
  validates :salary_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :salary_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :salary_range_valid

  def formatted_salary_range
    return nil if salary_min.blank? && salary_max.blank?

    symbol = CURRENCY_SYMBOLS.fetch(currency)
    [ salary_min, salary_max ].compact.map { |amount| "#{symbol}#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}" }.join(" - ")
  end

  scope :active, -> { where(status: :published) }
  # ILIKE (Postgres-specific case-insensitive LIKE) — plain LIKE is
  # case-sensitive on Postgres, unlike SQLite/MySQL's default collation,
  # so a lowercase search like "delhi" silently matched nothing against "Delhi".
  scope :search_title, ->(q) { where("title ILIKE :q", q: "%#{sanitize_sql_like(q)}%") if q.present? }
  scope :in_location, ->(loc) { where("location ILIKE :q", q: "%#{sanitize_sql_like(loc)}%") if loc.present? }
  scope :in_category, ->(cat) { where(category: cat) if cat.present? }
  scope :of_type, ->(type) { where(job_type: type) if type.present? }
  # NOTE: compares raw salary_max across currencies with no FX conversion —
  # fine while nearly all postings are INR, but a mixed-currency board needs
  # a normalized (e.g. USD-equivalent) column to filter on. See README.
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
