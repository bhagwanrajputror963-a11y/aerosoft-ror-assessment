module Admin
  class ApplicationsController < BaseController
    def index
      @pagy, @applications = pagy(
        Application.includes(job: :company, candidate: :user).order(created_at: :desc)
      )
    end
  end
end
