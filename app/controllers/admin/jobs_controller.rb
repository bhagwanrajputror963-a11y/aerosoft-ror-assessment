module Admin
  class JobsController < BaseController
    def index
      @pagy, @jobs = pagy(
        Job.includes(:company, recruiter: :user).order(created_at: :desc)
      )

      # Only the applicant count is shown, never the application records
      # themselves — see Admin::CompaniesController for why this is a
      # grouped count query rather than .includes(:applications).
      @application_counts = Application.where(job_id: @jobs.map(&:id)).group(:job_id).count
    end
  end
end
