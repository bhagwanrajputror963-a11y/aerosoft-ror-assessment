class DashboardsController < ApplicationController
  before_action :require_login

  def show
    case current_user.role
    when "candidate"
      @pagy, @applications = pagy(current_user.candidate.applications.includes(job: :company).order(created_at: :desc))
    when "recruiter"
      @pagy, @jobs = pagy(current_user.recruiter.jobs.includes(applications: { candidate: :user }).order(created_at: :desc))
    when "admin"
      @jobs_count = Job.count
      @applications_count = Application.count
      @companies_count = Company.count
      @candidates_count = Candidate.count
    end
  end
end
