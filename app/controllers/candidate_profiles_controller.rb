class CandidateProfilesController < ApplicationController
  before_action :require_login
  before_action { require_role(:candidate) }

  def edit
    @candidate = current_user.candidate
  end

  def update
    @candidate = current_user.candidate

    if @candidate.update(candidate_params)
      redirect_to dashboard_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def candidate_params
    params.require(:candidate).permit(:headline, :skills, :experience_years, :resume_url)
  end
end
