class Contingent
  extend Savon::Model
  include Singleton

  document Settings['contingent.wsdl']

  actions :log_on, :is_login, :get_students_by_criteria, :get_student_by_id, :get_all_active_groups

  def students(*args)
    []
  end
  class << self
    def login
      call :log_on, Settings['contingent.auth']
    end

    def logged_in?
      call :is_login
    end

    private

    def call(method, *args)
      self.send(method, *args)[:"#{method}_response"][:"#{method}_result"]
    end
  end
end
