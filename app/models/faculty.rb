class Faculty < Model
  attribute :name
  attribute :abbr

  def self.from(hash)
    Faculty.new(
      name: hash[:faculty_name],
      abbr: hash[:short_name],
    )
  end

end
