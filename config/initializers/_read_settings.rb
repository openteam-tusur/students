Settings.read Rails.root.join 'config', 'settings.yml'

Settings.define 'contingent.auth.login',    :required => true
Settings.define 'contingent.auth.password', :required => true
Settings.define 'contingent.wsdl',          :required => true

Settings.resolve!
