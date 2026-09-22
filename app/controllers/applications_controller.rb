class ApplicationsController < ApplicationController
  before_action :require_login
  before_action(-> { require_role(:candidate) }, only: [ :new, :create ])
  before_action :set_job, only: [ :new, :create ]

  def new
    @application = @job.applications.build
  end

  def create
    @application = @job.applications.build(application_params)
    @application.candidate = current_user.candidate

    if @application.save
      redirect_to dashboard_path, notice: "Application submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update_status
    application = Application.find(params[:id])
    unless current_user.recruiter && application.job.recruiter_id == current_user.recruiter.id
      return redirect_to dashboard_path, alert: "Not authorized."
    end

    if application.update(status: params[:status])
      redirect_to dashboard_path, notice: "Application status updated."
    else
      redirect_to dashboard_path, alert: application.errors.full_messages.to_sentence
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def application_params
    params.require(:application).permit(:cover_letter)
  end
end
