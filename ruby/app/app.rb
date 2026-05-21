require "sinatra/base"
require "json"
require "mysql2"

require_relative "db"
require_relative "errors"
require_relative "repository"
require_relative "service"

# HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
#
#   GET  /                  -> kleiner Health-Check
#   POST /api/bewerbungen   -> Bewerbung einreichen
#   GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)
class BewerbungApp < Sinatra::Base
  set :show_exceptions, false
  set :raise_errors, false

  get "/" do
    content_type "text/html; charset=utf-8"
    "<h1>Ruby / Sinatra laeuft</h1><p>API unter /api/bewerbungen</p>"
  end

  post "/api/bewerbungen" do
    content_type :json
    body = request.body.read
    input = begin
      JSON.parse(body)
    rescue JSON::ParserError
      halt 400, JSON.generate("fehler" => "Body muss gueltiges JSON sein.")
    end
    halt 400, JSON.generate("fehler" => "Body muss gueltiges JSON sein.") unless input.is_a?(Hash)

    conn = DB.connect
    begin
      svc = BewerbungService.new(MysqlBewerbungRepository.new(conn))
      result = svc.einreichen(input)
      status 201
      JSON.generate(result)
    rescue ValidationError => e
      status 400
      JSON.generate("fehler" => e.message, "details" => e.errors)
    rescue Mysql2::Error => e
      case e.error_number
      when 1452
        status 422
        JSON.generate("fehler" => "Angegebene stelle_id existiert nicht.")
      when 1062
        status 409
        JSON.generate("fehler" => "Vorgangsnummer-Kollision, bitte erneut senden.")
      else
        status 500
        JSON.generate("fehler" => "Datenbankfehler.")
      end
    ensure
      conn&.close
    end
  end

  get "/api/bewerbungen" do
    content_type :json
    conn = DB.connect
    begin
      svc = BewerbungService.new(MysqlBewerbungRepository.new(conn))
      status 200
      JSON.generate("bewerbungen" => svc.liste(params["status"]))
    rescue Mysql2::Error
      status 500
      JSON.generate("fehler" => "Datenbankfehler.")
    ensure
      conn&.close
    end
  end
end
