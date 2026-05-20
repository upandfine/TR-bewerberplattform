using System.Text.RegularExpressions;
using Bewerbung.Api;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository).
/// </summary>
public class ServiceTests
{
    private sealed class FakeRepo : IBewerbungRepository
    {
        private readonly Dictionary<string, int> _emails = new();
        private int _next = 1;

        public Task<int?> FindBewerberIdByEmailAsync(string email)
            => Task.FromResult<int?>(_emails.TryGetValue(email, out var id) ? id : null);

        public Task<int> InsertBewerberAsync(BewerberInput b)
        {
            var id = _next++;
            _emails[b.Email] = id;
            return Task.FromResult(id);
        }

        public Task<int> InsertBewerbungAsync(int bewerberId, int stelleId,
            string vorgangsNr, string? bemerkung)
            => Task.FromResult(_next++);

        public Task<IReadOnlyList<IDictionary<string, object?>>> ListBewerbungenAsync(string? status)
            => Task.FromResult<IReadOnlyList<IDictionary<string, object?>>>(
                new List<IDictionary<string, object?>>());
    }

    [Fact]
    public async Task Einreichen_liefert_Vorgangsnummer_im_Format()
    {
        var svc = new BewerbungService(new FakeRepo());
        var res = await svc.EinreichenAsync(new BewerbungInput(
            "Erika", "Mustermann", "erika@example.com", null, 1, null));

        Assert.Matches(@"^BEW-\d{4}-[0-9A-F]{6}$", res.VorgangsNr);
        Assert.True(res.BewerbungId > 0);
    }

    [Fact]
    public async Task Bekannte_Email_wird_wiederverwendet()
    {
        var svc = new BewerbungService(new FakeRepo());
        var a = await svc.EinreichenAsync(new BewerbungInput(
            "Max", "M", "max@example.com", null, 1, null));
        var b = await svc.EinreichenAsync(new BewerbungInput(
            "Max", "M", "max@example.com", null, 2, null));

        Assert.Equal(a.BewerberId, b.BewerberId);
    }

    [Fact]
    public async Task Fehlende_Pflichtfelder_werfen_ValidationException()
    {
        var svc = new BewerbungService(new FakeRepo());
        var ex = await Assert.ThrowsAsync<ValidationException>(() =>
            svc.EinreichenAsync(new BewerbungInput(null, null, "kaputt", null, 0, null)));

        Assert.True(ex.Errors.Count >= 3);
    }

    [Fact]
    public void GenerateVorgangsNr_Format()
    {
        Assert.Matches(@"^BEW-\d{4}-[0-9A-F]{6}$",
            BewerbungService.GenerateVorgangsNr());
    }
}
