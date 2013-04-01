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

    students_from(Rails.cache.fetch(filter.to_s, :expires_in => 1.hour) do
      call(:get_students_by_criteria, 'studentCriteria' => filter)
    end)
  end

  def groups
    Rails.cache.fetch('get_all_active_groups', :expires_in => 1.day) do
      call(:get_all_active_groups)[:group_dto]
    end
  end

  def find_group_by_number(number)
    group_from groups.detect{|g| g[:group_name] == number}
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
    students = students_result.try(:[], :student_dto) || []
    students = [students] if students.is_a?(Hash)
    students.map do |hash|
      p hash
      Student.new(
        :study_id => hash[:study_id],
        :person_id => hash[:person_id],
        :firstname => hash[:first_name],
        :patronymic => hash[:middle_name],
        :lastname => hash[:last_name],
        :born_on => hash[:birth_date],
        :year => hash[:group][:course],
        :group => group_from(hash[:group], hash[:education]),
        :learns => hash[:student_state][:name] == "Активный",
        :in_gpo => hash[:gpo],
      )
    end
  end

  def subfaculty_from(hash)
    Subfaculty.new(
      :name => hash[:sub_faculty][:sub_faculty_name],
      :abbr => hash[:sub_faculty][:short_name],
      :faculty => faculty_from(hash)
    )
  end

  def faculty_from(hash)
    Faculty.new(
      :name => hash[:faculty][:faculty_name],
      :abbr => hash[:faculty][:short_name],
    )
  end

  def group_from(hash, education=nil)
    education ||= hash[:education]
    Group.new(
      :number => hash[:group_name],
      :education_form => education_form_from(education),
      :speciality_code => education[:speciality][:speciality_code],
      :subfaculty => subfaculty_from(education),
    )
  end

  EDUCATION_FORMS = {
    'Заочная'       => 'postal',
    'Очная'         => 'full-time',
    'Очно-заочная'  => 'part-time',
  }

  def education_form_from(hash)
    EDUCATION_FORMS[hash[:edu_form][:edu_form_name]]
  end
end
