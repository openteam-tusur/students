class Model
  include ActiveAttr::BasicModel
  include ActiveAttr::MassAssignment
  include ActiveAttr::QueryAttributes
  include ActiveAttr::TypecastedAttributes
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include AttributeNormalizer
end
