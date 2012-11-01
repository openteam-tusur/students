# encoding: utf-8

require 'singleton'

class Contingent
  extend Savon::Model
  include Singleton

  document Settings['contingent.wsdl']

  actions :log_on, :is_login, :get_students_by_criteria, :get_student_by_id, :get_all_active_groups

  def students(params)
    filter = {
      'GroupName'  => params[:group],
      'LastName'   => params[:lastname],
      'FirstName'  => params[:firstname],
      'MiddleName' => params[:patronymic]
    }
    filter.delete_if { |key, value|  value.blank? }
    return [] if filter.empty?
    filter['StudentStateId'] = params[:learns] == 'no' ? 0 : 1

    students_from(call(:get_students_by_criteria, 'studentCriteria' => filter))
  end

  def groups
    auth_call :get_all_active_groups
  end

  private

  def call(method, options={})
    login
    self.send(method, options)[:"#{method}_response"][:"#{method}_result"]
  end

  def login
    self.send :log_on, Settings['contingent.auth']
  end

  def students_from(students_result)
    students_result[:student_dto].map do |hash|
      Student.new(
        :study_id => hash[:study_id],
        :firstname => hash[:first_name],
        :patronymic => hash[:middle_name],
        :lastname => hash[:last_name],
        :born_on => hash[:birth_date],
        :subfaculty => subfaculty_from(hash),
        :faculty => faculty_from(hash),
        :year => hash[:group][:course],
        :group => hash[:group][:group_name],
        :learns => hash[:student_state][:name] == "Активный" ? :yes : :no,
        :in_gpo => hash[:gpo]? :yes : :no,
      )
    end
  end

  def subfaculty_from(hash)
    Subfaculty.new(
      :name => hash[:education][:sub_faculty][:sub_faculty_name],
      :abbr => hash[:education][:sub_faculty][:short_name],
    )
  end

  def faculty_from(hash)
    Faculty.new(
      :name => hash[:education][:faculty][:faculty_name],
      :abbr => hash[:education][:faculty][:short_name],
    )
  end

end
