class SubfacultyStudent < Model
  attribute :student_id
  attribute :status
  attribute :group

  class << self
    def from(hash)
      begin
        vals = %i[study_id status_name group_name]
        student_id, status, group = hash.values_at(*vals)
        SubfacultyStudent.new(
          student_id: student_id,
          status: status,
          group: group
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
