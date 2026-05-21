namespace Bewerbung.Api;

/// <summary>
/// Naht zwischen Stellenangebot-Service (reine Logik) und Persistenz.
/// Im Unit-Test wird das Interface durch ein In-Memory-Fake ersetzt
/// -> Service-Tests brauchen keine Datenbank.
/// </summary>
public interface IStellenangebotRepository
{
    Task<int> InsertStelleAsync(StelleInput stelle);

    Task<IReadOnlyList<IDictionary<string, object?>>> ListStellenAsync(string? status);
}

public sealed record StelleInput(
    string Titel,
    string? Beschreibung,
    string Art,
    string Status);
