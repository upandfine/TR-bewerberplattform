$LOAD_PATH.unshift File.expand_path("../app", __dir__)

require "minitest/autorun"
require "net/http"
require "uri"
require "json"
require "securerandom"
require "db"

# API-/E2E-Test: echter HTTP-Durchstich gegen den im Container
# laufenden Server (http://localhost:8080).
class BewerbungApiTest < Minitest::Test
  BASE = URI("http://localhost:8080/api/bewerbungen").freeze

  def setup
    @email = "rbapi+#{SecureRandom.hex(8)}@example.com"
  end

  def teardown
    conn = DB.connect
    # ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber loeschen.
    stmt = conn.prepare(
      "DELETE FROM bewerbung WHERE bewerberId IN " \
      "(SELECT id FROM bewerber WHERE email = ?)"
    )
    stmt.execute(@email)
    stmt.close
    stmt = conn.prepare("DELETE FROM bewerber WHERE email = ?")
    stmt.execute(@email)
    stmt.close
    conn.close
  end

  def stelle_id
    conn = DB.connect
    row = conn.query("SELECT MIN(id) AS m FROM stellenangebot").first
    conn.close
    skip "Keine Stelle vorhanden - DB neu initialisieren." if row.nil? || row["m"].nil?
    row["m"].to_i
  end

  def request(method, body = nil)
    http = Net::HTTP.new(BASE.host, BASE.port)
    req = case method
          when "POST" then Net::HTTP::Post.new(BASE.path)
          when "GET"  then Net::HTTP::Get.new(BASE.path)
          end
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body) if body
    res = http.request(req)
    [res.code.to_i, JSON.parse(res.body || "null")]
  end

  def test_post_legt_an_und_get_listet
    status, post = request("POST",
      vorname: "API", nachname: "Tester",
      email: @email, stelle_id: stelle_id,
    )
    assert_equal 201, status, "Body: #{post.inspect}"
    nummer = post["vorgangs_nr"]
    refute_nil nummer

    status, get = request("GET")
    assert_equal 200, status
    nummern = get["bewerbungen"].map { |b| b["vorgangs_nr"] }
    assert_includes nummern, nummer
  end

  def test_post_mit_ungueltigen_daten_400
    status, body = request("POST", email: "kaputt", stelle_id: 0)
    assert_equal 400, status
    assert body.key?("details"), "details fehlen: #{body.inspect}"
  end
end
