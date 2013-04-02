class API::Students < Grape::API
  version 'v1', :using => :path

  logger Rails.logger

  rescue_from :all do |e|
    # Log it
    Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"

    # Notify external service of the error
    Airbrake.notify(e)

    # Send error and backtrace down to the client in the response body (only for internal/testing purposes of course)
    Rack::Response.new(["rescued from #{e.class.name}"], 500, { "Content-type" => "text/error" }).finish
  end

  format :json

  get :ping do
    :pong
  end

  namespace :groups do
    params do
      requires :group_number, :type => String, :desc => "number of group"
    end

    get ":group_number" do
      Contingent.instance.find_group_by_number(params[:group_number])
    end
  end

  namespace :students do
    helpers do
      def search
        @search ||= Search.new(params)
      end

      def finded_students
        @finded_students ||= Contingent.instance.students(search)
      end
    end

    get  { finded_students }
  end

  desc 'Redirect to work_plan'
  namespace :work_plans do
    params do
      requires :subspeciality_id, :type => Integer, :desc => "id of subspeciality"
    end
    get ":subspeciality_id" do
      redirect subspeciality.work_plan.try :file_url
    end
  end
end

