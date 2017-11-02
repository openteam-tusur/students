class Speciality < Model
  attribute :code
  attribute :name
  attribute :kind

  def self.from(hash)
    Speciality.new(
      code: hash[:speciality_code],
      name: hash[:speciality_name],
      kind: hash[:speciality_type_name]
    )
  end
end
