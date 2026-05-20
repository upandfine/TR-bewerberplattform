using Bewerbung.Api;
using MySqlConnector;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// INTEGRATION-Test gegen die ECHTE MariaDB.
/// Jeder Test in einer Transaktion, die zurückgerollt wird.
/// </summary>
public class RepositoryIntegrationTests : IAsyncLifetime
{
    private MySqlConnection _conn = default!;
    private MySqlTransaction _tx = default!;
    private MySqlBewerbungRepository _repo = default!;

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
        _repo = new MySqlBewerbungRepository(_conn, _tx);
    }

    public async Task DisposeAsync()
    {
        await _tx.RollbackAsync();
        await _conn.CloseAsync();
        await _conn.DisposeAsync();
    }

    private async Task<int> EineStelleIdAsync()
    {
        using var cmd = _conn.CreateCommand();
        cmd.Transaction = _tx;
        cmd.CommandText =
            "INSERT INTO stellenangebot (titel, art, status) " +
            "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')";
        await cmd.ExecuteNonQueryAsync();
        return (int)cmd.LastInsertedId;
    }

    [Fact]
    public async Task Bewerber_anlegen_und_per_Email_finden()
    {
        var id = await _repo.InsertBewerberAsync(new BewerberInput(
            "Erika", "Mustermann", "cs-int@example.com", null));

        Assert.Equal(id, await _repo.FindBewerberIdByEmailAsync("cs-int@example.com"));
        Assert.Null(await _repo.FindBewerberIdByEmailAsync("nope@example.com"));
    }

    [Fact]
    public async Task Bewerbung_anlegen_funktioniert()
    {
        var stelleId = await EineStelleIdAsync();
        var bewerberId = await _repo.InsertBewerberAsync(new BewerberInput(
            "Max", "M", "cs-m@example.com", null));

        var id = await _repo.InsertBewerbungAsync(
            bewerberId, stelleId, "BEW-2026-CSAB01", null);

        Assert.True(id > 0);
    }

    [Fact]
    public async Task Fremdschluessel_verhindert_ungueltige_Stelle()
    {
        var bewerberId = await _repo.InsertBewerberAsync(new BewerberInput(
            "A", "B", "cs-fk@example.com", null));

        var ex = await Assert.ThrowsAsync<MySqlException>(() =>
            _repo.InsertBewerbungAsync(bewerberId, 999999, "BEW-2026-CSFK01", null));

        Assert.Equal(1452, ex.Number);
    }

    [Fact]
    public async Task Vorgangsnummer_ist_eindeutig()
    {
        var stelleId = await EineStelleIdAsync();
        var bewerberId = await _repo.InsertBewerberAsync(new BewerberInput(
            "C", "D", "cs-uq@example.com", null));

        await _repo.InsertBewerbungAsync(bewerberId, stelleId, "BEW-2026-CSDUP1", null);

        var ex = await Assert.ThrowsAsync<MySqlException>(() =>
            _repo.InsertBewerbungAsync(bewerberId, stelleId, "BEW-2026-CSDUP1", null));

        Assert.Equal(1062, ex.Number);
    }
}
