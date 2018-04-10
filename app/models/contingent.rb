# encoding: utf-8
require 'singleton'

class Contingent
  extend Savon::Model
  include Singleton

  client wsdl: Settings['contingent.wsdl']

  global :soap_version, 2
  global :logger, Rails.logger
  global :log_level, :info

  OPERATIONS = %i[
    log_on
    is_login
    get_students_by_criteria
    get_student_by_id
    get_all_active_groups
    get_student_hostels
    get_students_by_subfac_common_id
  ]
  operations(*OPERATIONS)

  def students(search)
    filter = {
      'GroupName'  => search.group,
      'LastName'   => search.lastname,
      'FirstName'  => search.firstname,
      'MiddleName' => search.patronymic,
      'StudyId'    => search.study_id,
      'PersonId'   => search.person_id,
      'PreviousPersonId' => search.previous_person_id
    }
    filter.delete_if { |key, value| value.blank? }
    return [] if filter.empty?

    filter['StudentStateId'] = search.include_inactive? ? 0 : 1

    students = students_from(cached_call(:get_students_by_criteria, 'studentCriteria' => filter))
    if filter['GroupName'].present? && !filter['GroupName'].match(/_$/)
      filter['GroupName'] = %(#{filter['GroupName']}_)
      students += students_from(cached_call(:get_students_by_criteria, 'studentCriteria' => filter))
    end

    return students if !search.born_on

    students.select{|student| student.born_on == search.born_on}
  end

  def groups
    cached_call(:get_all_active_groups)
  end

  def find_student_by_study_id(study_id)
    Student.from cached_call(:get_student_by_id, 'studentId' => study_id)
  end

  def student_hostels(student)
    response = cached_call(:get_student_hostels, 'studyId' => student.study_id)
    HostelLiving.from_array(response || [])
  end

  def students_by_subfaculty(common_id)
    response = cached_call(:get_students_by_subfac_common_id, 'SubfacCommonId' => common_id)
    SubfacultyStudent.from_array(response || [])
  end

  private

  def cached_call(method, options={})
    expire_time = Rails.env.production?  ? 1.day : 1.second
    Rails.cache.fetch("#{method}-#{options}", expires_in: expire_time) do
      cookies = log_on(message: Settings['contingent.auth']).http.cookies
      response = self.send(method, message: options, cookies: cookies)
      result = response.body[:"#{method}_response"][:"#{method}_result"]
      dto?(result) ? result.values.first : result
    end
  end

  def dto?(result)
    result.is_a?(Hash) && result.one? && result.keys.first =~ /_dto$/
  end

  def students_from(students)
    students ||= []
    students = [students] if students.is_a?(Hash)
    students.map { |hash| Student.from(hash) }
  end
end
