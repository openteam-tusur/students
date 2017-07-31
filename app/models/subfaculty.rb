class Subfaculty < Model
  attribute :name
  attribute :abbr
  attribute :faculty

  def self.from(hash)
    Subfaculty.new(
      name: hash[:sub_faculty_name],
      abbr: hash[:short_name],
    )
  end
end
