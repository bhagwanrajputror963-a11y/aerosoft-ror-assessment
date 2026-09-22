module Admin
  class UsersController < BaseController
    def index
      @pagy, @users = pagy(
        User.includes(:candidate, recruiter: :company).order(created_at: :desc)
      )
    end
  end
end
