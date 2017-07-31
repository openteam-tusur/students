class Education < Model
  attribute :params

  delegate :subfaculty, :faculty, :course, :speciality, to: :group

  def initialize(params)
    self.params = params
  end

  def group
    @group ||= Group.from(params)
  end
end
