class Model
  include ActiveAttr::BasicModel
  include ActiveAttr::MassAssignment
  include ActiveAttr::QueryAttributes

  def as_json(*args)
    super['attributes']
  end
end
