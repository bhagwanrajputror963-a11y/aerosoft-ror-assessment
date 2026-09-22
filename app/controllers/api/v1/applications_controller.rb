module Api
  module V1
    # POST /api/v1/applications
    # params: { job_id: <id>, cover_letter: <string> }
    # requires an authenticated candidate (session cookie)
    class ApplicationsController < ApplicationController
      skip_before_action :verify_authenticity_token, raise: false

      def create
        return render json: { error: "Authentication required" }, status: :unauthorized unless logged_in?
        return render json: { error: "Only candidates can apply" }, status: :forbidden unless current_user.candidate?

        job = Job.find(params[:job_id])
        application = job.applications.build(
          candidate: current_user.candidate,
          cover_letter: params[:cover_letter]
        )

        if application.save
          render json: application, status: :created
        else
          render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
