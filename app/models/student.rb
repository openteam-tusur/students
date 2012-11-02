class Student < Model
  attribute :study_id
  attribute :person_id
  attribute :firstname
  attribute :patronymic
  attribute :lastname
  attribute :year
  attribute :group
  attribute :born_on,         :type => Date
  attribute :learns
  attribute :in_gpo
  attribute :subfaculty

  delegate :faculty, :faculty=, :to => :subfaculty

  normalize_attribute :firstname, :patronymic, :lastname, :group

  def name
    [lastname, firstname, patronymic].compact.join(' ')
  end

  def to_param
    study_id
  end
end
