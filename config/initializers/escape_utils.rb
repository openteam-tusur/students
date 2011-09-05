module Rack::Utils
  def escape(s)
    EscapeUtils.escape_url(s)
  end
  module_function :escape
end
