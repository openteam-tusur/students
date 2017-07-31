class Search < Model
  attribute :firstname
  attribute :patronymic
  attribute :lastname
  attribute :group
  attribute :include_inactive, type: Boolean
  attribute :person_id, type: Integer
  attribute :previous_person_id, type: Integer
  attribute :study_id, type: Integer
  attribute :born_on, type: Date

  normalize_attribute :firstname, :patronymic, :lastname, :group, :person_id, :previous_person_id, :study_id

  alias_attribute :id, :study_id
end
