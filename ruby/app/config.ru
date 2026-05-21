# Rack-Boot fuer Puma. Aufgerufen via:
#   bundle exec puma -b tcp://0.0.0.0:8080 app/config.ru
require_relative "app"
run BewerbungApp
