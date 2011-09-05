class Student < Model
  attr_accessor :subfaculty

  column :study_id,           :integer
  column :firstname,          :string
  column :patronymic,         :string
  column :lastname,           :string
  column :year,               :integer
  column :group,              :string
  column :born_on,            :date
  column :learns,             :string
  column :in_gpo,             :string

  delegate :faculty, :faculty=, :to => :subfaculty

  has_enums

  def self.find(*args)
    options = args.extract_options!
    if args.first == :all
      Contingent.instance.students(options)
    else
      Contingent.instance.student(args.first)
    end
  end

  def name
    "#{lastname} #{firstname} #{patronymic}"
  end

  def to_param
    study_id
  end

  def to_xml(options = {})
    builder = options[:builder] || Builder::XmlMarkup.new
    builder.student {
      builder.id          self.id
      builder.firstname   { |text| text << self.firstname  }
      builder.patronymic  { |text| text << self.patronymic }
      builder.lastname    { |text| text << self.lastname   }
      builder.born_on     self.born_on
      builder.in_gpo      self.in_gpo
      builder.learns      self.learns
    }
  end

end
