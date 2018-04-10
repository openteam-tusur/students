class HostelLiving < Model
  attribute :student_hostel_id
  attribute :hostel
  attribute :room_number
  attribute :start_date, type: Date
  attribute :end_date, type: Date

  class << self
    def from(hash)
      begin
        vals = %i[student_hoste_id hostel room_number start_date end_date]
        student_hostel_id, hostel, room_number, start_date, end_date = hash.values_at(*vals)
        HostelLiving.new(
          student_hostel_id: student_hostel_id,
          hostel: hostel,
          room_number: room_number,
          start_date: start_date,
          end_date: end_date
        )
      rescue
        nil
      end
    end

    def from_array(array_of_hashes)
      (array_of_hashes.kind_of?(Array) ? array_of_hashes : [array_of_hashes]).map{ |hash| from(hash) }.compact
    end
  end
end
