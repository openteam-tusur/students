class Speciality < Model
  attribute :code
  attribute :name

  def self.from(hash)
    Speciality.new(
      code: hash[:speciality_code],
      name: hash[:speciality_name],
    )
  end
end
