class Student < Model
  attr_accessor :subfaculty

  #attr_accessor :group, :lastname, :firstname, :patronymic, :learns, :in_gpo
  attribute :study_id   # Integer
  attribute :firstname  # String
  attribute :patronymic # String
  attribute :lastname   # String
  attribute :year       # Integer
  attribute :group      # String
  attribute :born_on    # Date
  attribute :learns     # String
  attribute :in_gpo     # String

  #delegate :faculty, :faculty=, :to => :subfaculty

  enumerize :learns, in: %w[yes no], predicates: { prefix: true }
  enumerize :in_gpo, in: %w[yes no], predicates: { prefix: true }

  ##has_enums

  #def self.find(*args)
    #options = args.extract_options!
    #if args.first == :all
      #Contingent.instance.students(options)
    #else
      #Contingent.instance.student(args.first)
    #end
  #end

  #def name
    #"#{lastname} #{firstname} #{patronymic}"
  #end

  #def to_param
    #study_id
  #end

end
