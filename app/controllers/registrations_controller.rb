class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    ActiveRecord::Base.transaction do
      @user.save!

      case @user.role
      when "candidate"
        Candidate.create!(user: @user)
      when "recruiter"
        company = Company.find_or_create_by!(name: params[:company_name])
        Recruiter.create!(user: @user, company: company, position: params[:position].presence || "Recruiter")
      end
    end

    session[:user_id] = @user.id
    redirect_to dashboard_path, notice: "Welcome to Flying Crews, #{@user.name}!"
  rescue ActiveRecord::RecordInvalid => e
    @user.errors.merge!(e.record.errors) unless e.record == @user
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
