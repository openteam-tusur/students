class StudentSearch < Student

  column :firstname,  :string
  column :patronymic, :string
  column :lastname,   :string
  column :group,      :string
  column :learns,     :string

  has_enums

  def students
    Contingent.instance.students self
  end

end
