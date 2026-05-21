using Bewerbung.Api;
using MySqlConnector;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// INTEGRATION-Test fuer das Stellenangebot-Repository gegen die
/// ECHTE MariaDB. Jeder Test in einer Transaktion mit Rollback.
/// </summary>
public class StellenRepositoryIntegrationTests : IAsyncLifetime
{
    private MySqlConnection _conn = default!;
    private MySqlTransaction _tx = default!;
    private MySqlStellenangebotRepository _repo = default!;

    public async Task InitializeAsync()
    {
        var cs =
            $"Server={Environment.GetEnvironmentVariable("DB_HOST")};Port=3306;" +
            $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
            $"User={Environment.GetEnvironmentVariable("DB_USER")};" +
            $"Password={Environment.GetEnvironmentVariable("DB_PASS")};";
        _conn = new MySqlConnection(cs);
        await _conn.OpenAsync();
        _tx = await _conn.BeginTransactionAsync();
        _repo = new MySqlStellenangebotRepository(_conn, _tx);
    }

    public async Task DisposeAsync()
    {
        await _tx.RollbackAsync();
        await _conn.CloseAsync();
        await _conn.DisposeAsync();
    }

    [Fact]
    public async Task Stelle_anlegen_liefert_Id()
    {
        var id = await _repo.InsertStelleAsync(new StelleInput(
            "Integration: Backend", "C#/MariaDB", "FESTANSTELLUNG", "ENTWURF"));
        Assert.True(id > 0);
    }

    [Fact]
    public async Task Liste_filtert_nach_Status()
    {
        await _repo.InsertStelleAsync(new StelleInput(
            "I-A", null, "FESTANSTELLUNG", "ENTWURF"));
        await _repo.InsertStelleAsync(new StelleInput(
            "I-B", null, "WERKSTUDENT", "VEROEFFENTLICHT"));

        var entwurf = await _repo.ListStellenAsync("ENTWURF");
        var titel = entwurf.Select(r => (string?)r["titel"]).ToList();
        Assert.Contains("I-A", titel);
        Assert.DoesNotContain("I-B", titel);
    }

    [Fact]
    public async Task Prepared_Statement_verhindert_SqlInjection()
    {
        // Klassischer Injection-Versuch: bei naivem Concat wuerde
        // hier eine zweite Anweisung ausgefuehrt. Da Parameter
        // gebunden werden, ist es nur ein normaler String.
        var boese = "Hacker'); DROP TABLE stellenangebot; --";
        var id = await _repo.InsertStelleAsync(new StelleInput(
            boese, null, "FESTANSTELLUNG", "ENTWURF"));

        var alle = await _repo.ListStellenAsync(null);
        var titel = alle.Select(r => (string?)r["titel"]).ToList();
        Assert.Contains(boese, titel);
        Assert.True(id > 0);
    }
}
