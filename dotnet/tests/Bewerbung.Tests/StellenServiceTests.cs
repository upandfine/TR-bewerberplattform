using Bewerbung.Api;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// UNIT-Test fuer StellenangebotService: ohne Datenbank (Fake-Repository).
/// </summary>
public class StellenServiceTests
{
    private sealed class FakeRepo : IStellenangebotRepository
    {
        public List<IDictionary<string, object?>> Rows { get; } = new();
        private int _next = 1;

        public Task<int> InsertStelleAsync(StelleInput s)
        {
            var id = _next++;
            Rows.Add(new Dictionary<string, object?>
            {
                ["id"]           = id,
                ["titel"]        = s.Titel,
                ["beschreibung"] = s.Beschreibung,
                ["art"]          = s.Art,
                ["status"]       = s.Status,
            });
            return Task.FromResult(id);
        }

        public Task<IReadOnlyList<IDictionary<string, object?>>> ListStellenAsync(string? status)
        {
            IEnumerable<IDictionary<string, object?>> q = Rows;
            if (status is not null)
            {
                q = q.Where(r => (string?)r["status"] == status);
            }
            return Task.FromResult<IReadOnlyList<IDictionary<string, object?>>>(q.ToList());
        }
    }

    [Fact]
    public async Task Neue_Stelle_startet_immer_als_ENTWURF()
    {
        var repo = new FakeRepo();
        var svc = new StellenangebotService(repo);

        // Wichtig: der HTTP-Input traegt kein Status-Feld - die Regel
        // ist bewusst nicht abhaengig von einem potentiell "geleakten"
        // Statuswert aus der Aussenwelt. Service setzt ENTWURF.
        var res = await svc.AnlegenAsync(new StelleHttpInput(
            "Senior Backend", null, "FESTANSTELLUNG"));

        Assert.Equal("ENTWURF", res.Status);
        Assert.Equal("ENTWURF", (string?)repo.Rows[0]["status"]);
    }

    [Fact]
    public async Task Standard_Art_ist_FESTANSTELLUNG()
    {
        var svc = new StellenangebotService(new FakeRepo());
        var res = await svc.AnlegenAsync(new StelleHttpInput("Praktikant", null, null));
        Assert.Equal("FESTANSTELLUNG", res.Art);
    }

    [Fact]
    public async Task Titel_ist_Pflicht()
    {
        var svc = new StellenangebotService(new FakeRepo());
        await Assert.ThrowsAsync<ValidationException>(() =>
            svc.AnlegenAsync(new StelleHttpInput("   ", null, null)));
    }

    [Fact]
    public async Task Ungueltige_Art_wird_abgelehnt()
    {
        var svc = new StellenangebotService(new FakeRepo());
        await Assert.ThrowsAsync<ValidationException>(() =>
            svc.AnlegenAsync(new StelleHttpInput("Stelle", null, "KEIN_ECHTER_TYP")));
    }

    [Fact]
    public async Task Liste_filtert_nach_Status()
    {
        var repo = new FakeRepo();
        var svc = new StellenangebotService(repo);

        await svc.AnlegenAsync(new StelleHttpInput("A", null, null));
        await svc.AnlegenAsync(new StelleHttpInput("B", null, null));
        await repo.InsertStelleAsync(new StelleInput(
            "C", null, "FESTANSTELLUNG", "VEROEFFENTLICHT"));

        var entwurf = await svc.ListeAsync("ENTWURF");
        Assert.Equal(2, entwurf.Count);
    }

    [Fact]
    public async Task Liste_mit_ungueltigem_Status_wirft()
    {
        var svc = new StellenangebotService(new FakeRepo());
        await Assert.ThrowsAsync<ValidationException>(() =>
            svc.ListeAsync("UNBEKANNT"));
    }
}
