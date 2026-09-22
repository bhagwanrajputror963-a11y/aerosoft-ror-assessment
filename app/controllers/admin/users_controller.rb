module Admin
  class UsersController < BaseController
    def index
      @pagy, @users = pagy(
        User.includes(:candidate, recruiter: :company).order(:role, :name)
      )
    end
  end
end
