namespace Bewerbung.Api;

/// <summary>
/// Naht zwischen Service (reine Logik) und Persistenz.
/// Im Unit-Test wird das Interface durch ein In-Memory-Fake ersetzt
/// -> Service-Tests brauchen keine Datenbank.
/// </summary>
public interface IBewerbungRepository
{
    Task<int?> FindBewerberIdByEmailAsync(string email);

    Task<int> InsertBewerberAsync(BewerberInput bewerber);

    Task<int> InsertBewerbungAsync(
        int bewerberId, int stelleId, string vorgangsNr, string? bemerkung);

    Task<IReadOnlyList<IDictionary<string, object?>>> ListBewerbungenAsync(string? status);
}

public sealed record BewerberInput(
    string Vorname, string Nachname, string Email, string? Telefon);
