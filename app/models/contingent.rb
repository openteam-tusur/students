# encoding: utf-8

require 'singleton'

class Contingent
  extend Savon::Model
  include Singleton

  document Settings['contingent.wsdl']

  actions :log_on, :is_login, :get_students_by_criteria, :get_student_by_id, :get_all_active_groups

  def students(search)
    filter = {
      'GroupName'  => search.group,
      'LastName'   => search.lastname,
      'FirstName'  => search.firstname,
      'MiddleName' => search.patronymic,
      'StudyId'    => search.study_id,
      'PersonId'   => search.person_id
    }
    filter.delete_if { |key, value| value.blank? }
    return [] if filter.empty?

    filter['StudentStateId'] = search.include_inactive? ? 0 : 1

    students = students_from(call(:get_students_by_criteria, 'studentCriteria' => filter))
    search.born_on ? students.select{|student| student.born_on == search.born_on} : students
  end

  def groups
    call(:get_all_active_groups)
  end

  def find_student_by_study_id(study_id)
    Student.from call(:get_student_by_id, 'studentId' => study_id)
  end

  private

  def call(method, options={})
    Rails.cache.fetch("#{method}-#{options}", :expires_in => 1.day) do
      login
      result = self.send(method, options)[:"#{method}_response"][:"#{method}_result"]
      dto?(result) ? result.values.first : result
    end
  end

  def dto?(result)
    result.is_a?(Hash) && result.one? && result.keys.first =~ /_dto$/
  end

  def login
    self.send :log_on, Settings['contingent.auth']
  end

  def students_from(students)
    students ||= []
    students = [students] if students.is_a?(Hash)
    students.map do |hash|
      Student.from(hash)
    end
  end
end
