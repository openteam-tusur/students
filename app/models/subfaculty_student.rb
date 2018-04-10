class SubfacultyStudent < Model
  attribute :student_id
  attribute :status

  class << self
    def from(hash)
      begin
        vals = %i[study_id status_name]
        student_id, status = hash.values_at(*vals)
        SubfacultyStudent.new(
          student_id: student_id,
          status: status
        )
      rescue
        nil
      end
    end

    def from_array(array_of_hashes)
      array_of_hashes.map{ |hash| from(hash) }.compact
    end
  end
end
