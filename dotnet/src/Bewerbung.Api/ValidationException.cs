namespace Bewerbung.Api;

/// <summary>
/// Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.
/// </summary>
public sealed class ValidationException : Exception
{
    public IReadOnlyList<string> Errors { get; }

    public ValidationException(IReadOnlyList<string> errors)
        : base("Validierung fehlgeschlagen")
    {
        Errors = errors;
    }
}
