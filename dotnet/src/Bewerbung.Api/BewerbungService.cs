using System.Security.Cryptography;

namespace Bewerbung.Api;

/// <summary>
/// Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
/// Genau deshalb ohne Datenbank unit-testbar (Fake-Repository).
/// </summary>
public sealed class BewerbungService
{
    private readonly IBewerbungRepository _repo;

    public BewerbungService(IBewerbungRepository repo)
    {
        _repo = repo;
    }

    public async Task<EinreichenResult> EinreichenAsync(BewerbungInput input)
    {
        Validate(input);

        var email = input.Email!.Trim();

        var bewerberId = await _repo.FindBewerberIdByEmailAsync(email);
        bewerberId ??= await _repo.InsertBewerberAsync(new BewerberInput(
            input.Vorname!.Trim(),
            input.Nachname!.Trim(),
            email,
            string.IsNullOrWhiteSpace(input.Telefon) ? null : input.Telefon!.Trim()
        ));

        var vorgangsNr = GenerateVorgangsNr();
        var bewerbungId = await _repo.InsertBewerbungAsync(
            bewerberId.Value,
            input.StelleId!.Value,
            vorgangsNr,
            string.IsNullOrWhiteSpace(input.Bemerkung) ? null : input.Bemerkung!.Trim()
        );

        return new EinreichenResult(bewerbungId, bewerberId.Value, vorgangsNr);
    }

    public Task<IReadOnlyList<IDictionary<string, object?>>> ListeAsync(string? status)
        => _repo.ListBewerbungenAsync(status);

    public static string GenerateVorgangsNr()
        => $"BEW-{DateTime.UtcNow.Year}-{RandomNumberGenerator.GetInt32(0, 0x1000000):X6}";

    private static void Validate(BewerbungInput i)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(i.Vorname))
            errors.Add("Feld 'vorname' ist ein Pflichtfeld.");
        if (string.IsNullOrWhiteSpace(i.Nachname))
            errors.Add("Feld 'nachname' ist ein Pflichtfeld.");

        var email = (i.Email ?? string.Empty).Trim();
        var at = email.IndexOf('@');
        if (at < 1 || !email[(at + 1)..].Contains('.'))
        {
            errors.Add("Feld 'email' ist keine gültige E-Mail-Adresse.");
        }

        if (i.StelleId is null || i.StelleId <= 0)
        {
            errors.Add("Feld 'stelle_id' muss eine positive Zahl sein.");
        }

        if (errors.Count > 0) throw new ValidationException(errors);
    }
}

public sealed record BewerbungInput(
    string? Vorname,
    string? Nachname,
    string? Email,
    string? Telefon,
    int? StelleId,
    string? Bemerkung
);

public sealed record EinreichenResult(int BewerbungId, int BewerberId, string VorgangsNr);
