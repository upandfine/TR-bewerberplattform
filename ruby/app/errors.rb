# Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.
class ValidationError < StandardError
  attr_reader :errors

  def initialize(errors)
    super("Validierung fehlgeschlagen")
    @errors = errors
  end
end
