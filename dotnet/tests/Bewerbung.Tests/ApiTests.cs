using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using MySqlConnector;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
/// (Kestrel -> Service -> Repository -> MariaDB), im Container gegen
/// http://localhost:8080.
/// </summary>
public class ApiTests : IAsyncLifetime
{
    private const string Base = "http://localhost:8080/api/bewerbungen";
    private string _email = string.Empty;

    public Task InitializeAsync()
    {
        _email = $"csapi+{Guid.NewGuid():N}@example.com";
        return Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        if (string.IsNullOrEmpty(_email)) return;
        var cs =
            $"Server={Environment.GetEnvironmentVariable("DB_HOST")};Port=3306;" +
            $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
            $"User={Environment.GetEnvironmentVariable("DB_USER")};" +
            $"Password={Environment.GetEnvironmentVariable("DB_PASS")};";
        await using var c = new MySqlConnection(cs);
        await c.OpenAsync();
        // ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber löschen
        await using (var cmd = c.CreateCommand())
        {
            cmd.CommandText =
                "DELETE FROM bewerbung WHERE bewerberId IN " +
                "(SELECT id FROM bewerber WHERE email = @e)";
            cmd.Parameters.AddWithValue("@e", _email);
            await cmd.ExecuteNonQueryAsync();
        }
        await using (var cmd = c.CreateCommand())
        {
            cmd.CommandText = "DELETE FROM bewerber WHERE email = @e";
            cmd.Parameters.AddWithValue("@e", _email);
            await cmd.ExecuteNonQueryAsync();
        }
    }

    private static async Task<int> StelleIdAsync()
    {
        var cs =
            $"Server={Environment.GetEnvironmentVariable("DB_HOST")};Port=3306;" +
            $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
            $"User={Environment.GetEnvironmentVariable("DB_USER")};" +
            $"Password={Environment.GetEnvironmentVariable("DB_PASS")};";
        await using var c = new MySqlConnection(cs);
        await c.OpenAsync();
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT MIN(id) FROM stellenangebot";
        var r = await cmd.ExecuteScalarAsync();
        return r is null or DBNull ? 0 : Convert.ToInt32(r);
    }

    [Fact]
    public async Task POST_legt_an_und_GET_listet()
    {
        var stelleId = await StelleIdAsync();
        Assert.True(stelleId > 0, "Keine Stelle vorhanden - DB neu initialisieren.");

        using var http = new HttpClient();

        var post = await http.PostAsJsonAsync(Base, new
        {
            vorname = "API",
            nachname = "Tester",
            email = _email,
            stelle_id = stelleId
        });
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);

        var postBody = JsonDocument.Parse(await post.Content.ReadAsStringAsync()).RootElement;
        var nummer = postBody.GetProperty("vorgangs_nr").GetString();
        Assert.False(string.IsNullOrEmpty(nummer));

        var get = await http.GetAsync(Base);
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);

        var list = JsonDocument.Parse(await get.Content.ReadAsStringAsync())
            .RootElement.GetProperty("bewerbungen");
        var nummern = list.EnumerateArray()
            .Select(e => e.GetProperty("vorgangs_nr").GetString())
            .ToList();
        Assert.Contains(nummer, nummern);
    }

    [Fact]
    public async Task POST_mit_ungueltigen_Daten_400()
    {
        using var http = new HttpClient();
        var res = await http.PostAsJsonAsync(Base, new { email = "kaputt", stelle_id = 0 });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        var body = JsonDocument.Parse(await res.Content.ReadAsStringAsync()).RootElement;
        Assert.True(body.TryGetProperty("details", out _));
    }
}
