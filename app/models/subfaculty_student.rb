class SubfacultyStudent < Model
  attribute :student_id
  attribute :status
  attribute :group
  attribute :fullname
  attribute :course
  attribute :education_info

  class << self
    def from(hash)
      begin
        vals = %i[study_id status_name group_name course edu_level]
        student_id, status, group, course, education_info = hash.values_at(*vals)
        fullname = %(#{hash[:surname]} #{hash[:name]} #{hash[:patronymic]})
        SubfacultyStudent.new(
          student_id: student_id,
          status: status,
          group: group,
          fullname: fullname,
          course: course,
          education_info: education_info
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
