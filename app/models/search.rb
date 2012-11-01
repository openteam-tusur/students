class Search < Model
  attribute :firstname
  attribute :patronymic
  attribute :lastname
  attribute :group
  attribute :include_inactive, :type => ActiveAttr::Typecasting::Boolean
end
