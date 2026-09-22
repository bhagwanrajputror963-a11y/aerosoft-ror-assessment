module Api
  module V1
    # GET /api/v1/jobs?q=&location=&category=&job_type=&min_salary=
    # GET /api/v1/jobs/:id
    class JobsController < ApplicationController
      skip_before_action :verify_authenticity_token, raise: false

      def index
        jobs = Job.filter(search_params).includes(:company)
        render json: jobs.as_json(
          only: [ :id, :title, :location, :job_type, :category, :currency, :salary_min, :salary_max, :status, :posted_at ],
          include: { company: { only: [ :id, :name, :location ] } }
        )
      end

      def show
        job = Job.includes(:company).find(params[:id])
        render json: job.as_json(include: { company: { only: [ :id, :name, :location, :website ] } })
      end

      private

      def search_params
        params.permit(:q, :location, :category, :job_type, :min_salary)
      end
    end
  end
end
