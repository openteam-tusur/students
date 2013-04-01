class Group < Model
  attribute :number
  attribute :education_form
  attribute :speciality_code
  attribute :subfaculty

  def to_s
    number
  end
end
