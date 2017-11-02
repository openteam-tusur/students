# encoding: utf-8

class Student < Model
  attribute :study_id
  attribute :person_id
  attribute :previous_person_id
  attribute :firstname
  attribute :patronymic
  attribute :lastname
  attribute :gender
  attribute :born_on, type: Date
  attribute :citizenship
  attribute :begin_study
  attribute :end_study
  attribute :learns
  attribute :in_gpo
  attribute :group
  attribute :zach_number
  attribute :financing
  attribute :activate_date
  attribute :student_state

  attribute :education

  delegate :group, :subfaculty, :faculty, :course, :speciality, to: :education

  normalize_attribute :firstname, :patronymic, :lastname, :group

  def name
    [lastname, firstname, patronymic].compact.join(' ')
  end

  def to_param
    study_id
  end

  def self.from(hash)
    Student.new(
      study_id: hash[:study_id],
      person_id: hash[:person_id],
      previous_person_id: hash[:previous_person_id],
      firstname: hash[:first_name],
      patronymic: hash[:middle_name],
      lastname: hash[:last_name],
      gender: hash[:sex].gsub('М', 'мужской').gsub('Ж', 'женский'),
      born_on: hash[:birth_date],
      education: Education.new(hash[:education].merge(hash[:group])),
      begin_study: %(01.09.#{hash[:group][:year_forming]}),
      end_study: hash[:student_state][:name] == 'Окончил' ? I18n.l(hash[:activate_date]) : nil,
      learns: hash[:student_state][:name] == 'Активный',
      in_gpo: hash[:gpo],
      zach_number: hash[:zach_number],
      activate_date: hash[:activate_date],
      citizenship: hash[:citizenship][:name],
      student_state: hash[:student_state][:name],
      financing: hash[:financing]
    )
  end
end
