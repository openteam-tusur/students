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
    filter.delete_if { |key, value| value.nil? }
    return [] if filter.empty?

    filter['StudentStateId'] = search.include_inactive? ? 0 : 1

    students_from call(:get_students_by_criteria, 'studentCriteria' => filter, :expires_in => 1.hour)
  end

  def groups
    call(:get_all_active_groups, :expires_in => 1.day)
  end

  def find_group_by_number(number)
    group_hash = groups.detect{|g| g[:group_name] == number}
    Group.from group_hash.merge group_hash[:education]
  end

  private

  def call(method, options={})
    expires_in = options.delete(:expires_in) || 1.minute
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
    students = [students] if students.is_a?(Hash)
    students.map do |hash|
      Student.from(hash)
    end
  end
end
