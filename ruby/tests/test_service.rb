$LOAD_PATH.unshift File.expand_path("../app", __dir__)

require "minitest/autorun"
require "errors"
require "service"

# UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository).
class BewerbungServiceTest < Minitest::Test
  class FakeRepo
    def initialize
      @emails = {}
      @next_id = 1
    end

    def find_bewerber_id_by_email(email)
      @emails[email]
    end

    def insert_bewerber(b)
      id = @next_id
      @next_id += 1
      @emails[b[:email]] = id
      id
    end

    def insert_bewerbung(_bewerber_id, _stelle_id, _vorgangs_nr, _bemerkung)
      id = @next_id
      @next_id += 1
      id
    end

    def list_bewerbungen(_status)
      []
    end
  end

  def test_einreichen_liefert_vorgangsnummer_im_format
    svc = BewerbungService.new(FakeRepo.new)
    r = svc.einreichen(
      "vorname" => "Erika", "nachname" => "Mustermann",
      "email" => "erika@example.com", "stelle_id" => 1,
    )
    assert_match(/\ABEW-\d{4}-[0-9A-F]{6}\z/, r["vorgangs_nr"])
    assert_kind_of Integer, r["bewerbung_id"]
  end

  def test_bekannte_email_wird_wiederverwendet
    svc = BewerbungService.new(FakeRepo.new)
    a = svc.einreichen(
      "vorname" => "Max", "nachname" => "M",
      "email" => "max@example.com", "stelle_id" => 1,
    )
    b = svc.einreichen(
      "vorname" => "Max", "nachname" => "M",
      "email" => "max@example.com", "stelle_id" => 2,
    )
    assert_equal a["bewerber_id"], b["bewerber_id"]
  end

  def test_fehlende_pflichtfelder_werfen_validation_error
    svc = BewerbungService.new(FakeRepo.new)
    e = assert_raises(ValidationError) do
      svc.einreichen("email" => "kaputt", "stelle_id" => 0)
    end
    assert_operator e.errors.size, :>=, 3
  end

  def test_generate_vorgangs_nr_format
    assert_match(/\ABEW-\d{4}-[0-9A-F]{6}\z/, BewerbungService.generate_vorgangs_nr)
  end
end
