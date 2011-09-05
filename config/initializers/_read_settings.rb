Settings.read Rails.root.join 'config', 'settings.yml'

Settings.define 'auth.login',           :required => true
Settings.define 'auth.password',        :required => true

Settings.define 'contingent.namespace', :required => true
Settings.define 'contingent.endpoint',  :required => true

Settings.resolve!
