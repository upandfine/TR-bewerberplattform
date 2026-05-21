require "securerandom"
require "date"

require_relative "errors"

# Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
# Genau deshalb ohne Datenbank unit-testbar (Fake-Repository).
class BewerbungService
  def initialize(repo)
    @repo = repo
  end

  def einreichen(input)
    self.class.validate(input)

    email = input["email"].to_s.strip

    bewerber_id = @repo.find_bewerber_id_by_email(email)
    if bewerber_id.nil?
      bewerber_id = @repo.insert_bewerber(
        vorname:  input["vorname"].to_s.strip,
        nachname: input["nachname"].to_s.strip,
        email:    email,
        telefon:  input["telefon"]&.to_s&.strip&.then { |s| s.empty? ? nil : s },
      )
    end

    vorgangs_nr = self.class.generate_vorgangs_nr
    bewerbung_id = @repo.insert_bewerbung(
      bewerber_id,
      input["stelle_id"].to_i,
      vorgangs_nr,
      input["bemerkung"]&.to_s&.strip&.then { |s| s.empty? ? nil : s },
    )

    {
      "bewerbung_id" => bewerbung_id,
      "bewerber_id"  => bewerber_id,
      "vorgangs_nr"  => vorgangs_nr,
    }
  end

  def liste(status = nil)
    @repo.list_bewerbungen(status)
  end

  def self.generate_vorgangs_nr
    # SecureRandom.random_number nutzt eine kryptographische Zufallsquelle.
    "BEW-#{Date.today.year}-%06X" % SecureRandom.random_number(0x1000000)
  end

  def self.validate(input)
    errors = []

    %w[vorname nachname].each do |feld|
      errors << "Feld '#{feld}' ist ein Pflichtfeld." if input[feld].to_s.strip.empty?
    end

    email = input["email"].to_s.strip
    at = email.index("@") || -1
    if at < 1 || !email[(at + 1)..].to_s.include?(".")
      errors << "Feld 'email' ist keine gueltige E-Mail-Adresse."
    end

    stelle = input["stelle_id"]
    ok = stelle.is_a?(Integer) ? stelle.positive? : stelle.to_s.match?(/\A\d+\z/) && stelle.to_i.positive?
    errors << "Feld 'stelle_id' muss eine positive Zahl sein." unless ok

    raise ValidationError, errors unless errors.empty?
  end
end
