class API::Students < Grape::API
  version 'v1', using: :path

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
    get "/" do
      Contingent.instance.groups
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
end

