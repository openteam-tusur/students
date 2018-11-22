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

  get '/student/:id' do
    student = Contingent.instance.find_student_by_study_id(params[:id])
    student.attributes.merge(hostel_data: student.hostel_data)
  end

  namespace :groups do
    get "/" do
      if params[:aspirant]
        groups = Aspirant.collection(params.merge({
          op: 'GetAllActiveGraduateGroups'
        }))
      else
        groups = Contingent.instance.groups
      end
      groups = groups.select { |group|
        group[:group_name] == params[:number]
      } if params[:number].present?

      groups.each do |g|
        params = {
          group: g[:group_name],
          include_inactive: '1'
        }
        if g[:group_name].scan(/\d{6}-\d/).any?
          g[:students] = Aspirant.collection(params).count
          params[:include_inactive] = '0'
          g[:active_students] = Aspirant.collection(params).count
        else
          g[:students] = Contingent.instance.students(Search.new(params)).count
          params[:include_inactive] = '0'

          active_students = Contingent.instance.students(Search.new(params))
          g[:active_students] = active_students.count
          g[:budget_active_students] = active_students.select{|as| as[:financing] == 'Бюджет'}.count
          g[:paid_active_students] = active_students.select{|as| as[:financing] == 'ПВЗ'}.count
        end
      end

      groups
    end
  end

  namespace :students do
    helpers do
      def search
        @search ||= Search.new(params)
      end

      def finded_students
        if params[:aspirant] == 'true'
          @finded_students ||= Aspirant.collection(params)
        else
          @finded_students ||= Contingent.instance.students(search)
        end
      end

      def by_subfaculty
        students = Contingent.instance.students_by_subfaculty(params[:subfaculty_id])

        if params[:status]
          students = students.select { |student| params[:status].include? student.status }
        end

        students
      end
    end

    get '/' do
      finded_students
    end

    get 'by_subfaculty' do
      by_subfaculty
    end
  end
end
