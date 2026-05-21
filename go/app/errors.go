package main

// ValidationError ist der fachliche Validierungsfehler -> wird im
// HTTP-Handler zu 400.
type ValidationError struct {
	Errors []string
}

func (e *ValidationError) Error() string { return "Validierung fehlgeschlagen" }
