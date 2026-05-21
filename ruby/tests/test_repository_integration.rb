$LOAD_PATH.unshift File.expand_path("../app", __dir__)

require "minitest/autorun"
require "mysql2"
require "db"
require "repository"

# INTEGRATION-Test gegen die ECHTE MariaDB.
# Jeder Test in einer Transaktion, die zurueckgerollt wird.
class JdbcBewerbungRepositoryTest < Minitest::Test
  def setup
    @conn = DB.connect
    @conn.query("START TRANSACTION")
    @repo = MysqlBewerbungRepository.new(@conn)
  end

  def teardown
    @conn&.query("ROLLBACK")
    @conn&.close
  end

  def eine_stelle_id
    @conn.query(
      "INSERT INTO stellenangebot (titel, art, status) " \
      "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')"
    )
    @conn.last_id
  end

  def test_bewerber_anlegen_und_per_email_finden
    id = @repo.insert_bewerber(
      vorname: "Erika", nachname: "Mustermann",
      email: "rb-int@example.com", telefon: nil,
    )
    assert_equal id, @repo.find_bewerber_id_by_email("rb-int@example.com")
    assert_nil @repo.find_bewerber_id_by_email("unbekannt@example.com")
  end

  def test_bewerbung_anlegen_funktioniert
    stelle_id = eine_stelle_id
    bid = @repo.insert_bewerber(
      vorname: "Max", nachname: "M", email: "rb-m@example.com", telefon: nil,
    )
    aid = @repo.insert_bewerbung(bid, stelle_id, "BEW-2026-RBAB01", nil)
    assert_operator aid, :>, 0
  end

  def test_fremdschluessel_verhindert_ungueltige_stelle
    bid = @repo.insert_bewerber(
      vorname: "A", nachname: "B", email: "rb-fk@example.com", telefon: nil,
    )
    e = assert_raises(Mysql2::Error) do
      @repo.insert_bewerbung(bid, 999_999, "BEW-2026-RBFK01", nil)
    end
    assert_equal 1452, e.error_number
  end

  def test_vorgangsnummer_ist_eindeutig
    stelle_id = eine_stelle_id
    bid = @repo.insert_bewerber(
      vorname: "C", nachname: "D", email: "rb-uq@example.com", telefon: nil,
    )
    @repo.insert_bewerbung(bid, stelle_id, "BEW-2026-RBDUP1", nil)
    e = assert_raises(Mysql2::Error) do
      @repo.insert_bewerbung(bid, stelle_id, "BEW-2026-RBDUP1", nil)
    end
    assert_equal 1062, e.error_number
  end
end
