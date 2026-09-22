class JobsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :require_recruiter, only: [ :new, :create ]
  before_action :require_recruiter_or_admin, only: [ :edit, :update, :destroy ]
  before_action :set_job, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    @pagy, @jobs = pagy(Job.filter(search_params).includes(:company))
    @applied_job_statuses = applied_job_statuses_for(@jobs)
  end

  def show
    @existing_application = current_user.candidate.applications.find_by(job: @job) if logged_in? && current_user.candidate?
  end

  def new
    @job = current_user.recruiter.jobs.build
  end

  def create
    @job = current_user.recruiter.jobs.build(job_params)
    @job.company = current_user.recruiter.company
    @job.posted_at ||= Time.current

    if @job.save
      redirect_to @job, notice: "Job posted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @job.update(job_params)
      redirect_to @job, notice: "Job updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job.destroy
    redirect_to jobs_path, notice: "Job removed."
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def authorize_owner!
    return if current_user.admin?
    unless current_user.recruiter && @job.recruiter_id == current_user.recruiter.id
      redirect_to jobs_path, alert: "You can only manage jobs you posted."
    end
  end

  def require_recruiter
    require_role(:recruiter)
  end

  def require_recruiter_or_admin
    require_role(:recruiter, :admin)
  end

  def job_params
    params.require(:job).permit(:title, :description, :location, :job_type, :category,
                                 :salary_min, :salary_max, :currency, :status, :posted_at)
  end

  def search_params
    params.permit(:q, :location, :category, :job_type, :min_salary)
  end

  # One query for the whole page, not one per job card — {job_id => status}.
  def applied_job_statuses_for(jobs)
    return {} unless logged_in? && current_user.candidate?

    # Not .pluck(:job_id, :status) — status is an enum, and pluck returns the
    # raw integer, not the cast string label the view expects.
    current_user.candidate.applications.where(job_id: jobs.map(&:id))
      .each_with_object({}) { |application, statuses| statuses[application.job_id] = application.status }
  end
end
