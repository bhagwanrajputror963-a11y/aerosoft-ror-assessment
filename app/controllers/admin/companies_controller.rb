module Admin
  class CompaniesController < BaseController
    def index
      @pagy, @companies = pagy(Company.order(created_at: :desc))

      # Only the counts are shown, never the loaded job/recruiter records
      # themselves — .includes(:jobs, :recruiters) would eager-load rows
      # nothing ever iterates over (Bullet correctly flags that as unused).
      # One grouped query each instead, same idea as JobsController's
      # applied_job_statuses_for.
      company_ids = @companies.map(&:id)
      @job_counts = Job.where(company_id: company_ids).group(:company_id).count
      @recruiter_counts = Recruiter.where(company_id: company_ids).group(:company_id).count
    end
  end
end
