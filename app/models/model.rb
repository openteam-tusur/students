class Model
  extend Enumerize
  include ActiveAttr::BasicModel
  include ActiveAttr::MassAssignment
  include ActiveAttr::QueryAttributes
end
