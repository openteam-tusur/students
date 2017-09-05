class Group < Model
  attribute :number
  attribute :course
  attribute :year_forming
  attribute :education_form
  attribute :subfaculty
  attribute :speciality

  delegate :faculty, :faculty=, to: :subfaculty

  def to_s
    number
  end

  def self.from(hash)
    Group.new(
      number: hash[:group_name].gsub(/_$/, ''),
      course: hash[:course],
      year_forming: hash[:year_forming],
      education_form: EducationForm.from(hash[:edu_form]),
      subfaculty: Subfaculty.from(hash[:sub_faculty]),
      faculty: Faculty.from(hash[:faculty]),
      speciality: Speciality.from(hash[:speciality]),
    )
  end
end
