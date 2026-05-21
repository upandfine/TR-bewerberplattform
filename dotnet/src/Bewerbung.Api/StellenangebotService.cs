namespace Bewerbung.Api;

/// <summary>
/// Use-Case-Schicht fuer Stellenangebote: reine Fachlogik, kennt
/// weder DB noch HTTP.
///
/// Wichtigste Geschaeftsregel:
///   Eine neue Stelle startet IMMER mit Status 'ENTWURF'.
///   Ein vom Aufrufer gelieferter Status wird bewusst ignoriert.
/// </summary>
public sealed class StellenangebotService
{
    public const string StatusEntwurf = "ENTWURF";

    public static readonly IReadOnlyList<string> Arten = new[]
    {
        "FESTANSTELLUNG", "AZUBI", "MINIJOB", "WERKSTUDENT", "PRAKTIKUM",
    };

    public static readonly IReadOnlyList<string> Stati = new[]
    {
        "ENTWURF", "VEROEFFENTLICHT", "GESCHLOSSEN", "ARCHIVIERT",
    };

    private readonly IStellenangebotRepository _repo;

    public StellenangebotService(IStellenangebotRepository repo)
    {
        _repo = repo;
    }

    public async Task<AnlegenResult> AnlegenAsync(StelleHttpInput input)
    {
        Validate(input);

        var titel = input.Titel!.Trim();
        var beschreibung = string.IsNullOrWhiteSpace(input.Beschreibung)
            ? null
            : input.Beschreibung!.Trim();
        var art = string.IsNullOrWhiteSpace(input.Art) ? "FESTANSTELLUNG" : input.Art!;

        // Geschaeftsregel: neue Stellen starten IMMER als ENTWURF.
        var status = StatusEntwurf;

        var id = await _repo.InsertStelleAsync(new StelleInput(
            titel, beschreibung, art, status));

        return new AnlegenResult(id, titel, art, status);
    }

    public Task<IReadOnlyList<IDictionary<string, object?>>> ListeAsync(string? status)
    {
        if (status is not null && !Stati.Contains(status))
        {
            throw new ValidationException(new[]
            {
                "Parameter 'status' ist kein gueltiger Stellenstatus.",
            });
        }
        return _repo.ListStellenAsync(status);
    }

    private static void Validate(StelleHttpInput i)
    {
        var errors = new List<string>();

        var titel = (i.Titel ?? string.Empty).Trim();
        if (string.IsNullOrEmpty(titel))
        {
            errors.Add("Feld 'titel' ist ein Pflichtfeld.");
        }
        else if (titel.Length > 120)
        {
            errors.Add("Feld 'titel' darf maximal 120 Zeichen lang sein.");
        }

        if (!string.IsNullOrEmpty(i.Art) && !Arten.Contains(i.Art))
        {
            errors.Add("Feld 'art' ist keine gueltige Stellenart.");
        }

        if (errors.Count > 0) throw new ValidationException(errors);
    }
}

public sealed record StelleHttpInput(
    string? Titel,
    string? Beschreibung,
    string? Art
);

public sealed record AnlegenResult(int Id, string Titel, string Art, string Status);
