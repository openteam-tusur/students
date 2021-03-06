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

  get '/student/:id/orders_data' do
    student = Contingent.instance.find_student_by_study_id(params[:id])
    student.attributes.slice("lastname", "firstname", "patronymic", "study_id").merge(orders_data: student.orders_data)
  end

  namespace :groups do
    get "/" do
      if params[:number] =~ /\d{6}-\d/ || params[:aspirant] == 'true'
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
        if g[:group_name] =~ /\d{6}-\d/
          active_students = Aspirant.collection(params)
        else
          active_students = Contingent.instance.students(Search.new(params))
        end
        g[:students] = active_students.count

        active_students = active_students.select{ |student| student.learns? }
        g[:active_students] = active_students.count
        g[:budget_active_students] = active_students.select{|as| as[:financing] == 'Бюджет'}.count
        g[:paid_active_students] = active_students.select{|as| as[:financing] == 'ПВЗ'}.count
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
        if params[:group] =~ /\d{6}-\d/ || params[:aspirant] == 'true'
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
