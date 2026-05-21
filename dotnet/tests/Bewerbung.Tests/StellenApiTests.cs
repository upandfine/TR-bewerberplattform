using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using MySqlConnector;
using Xunit;

namespace Bewerbung.Tests;

/// <summary>
/// API-/E2E-Test fuer /api_stellen: echter HTTP-Durchstich
/// (Kestrel -> Service -> Repository -> MariaDB), im Container
/// gegen http://localhost:8080.
/// </summary>
public class StellenApiTests : IAsyncLifetime
{
    private const string Base = "http://localhost:8080/api_stellen";
    private string _titel = string.Empty;

    public Task InitializeAsync()
    {
        _titel = $"csapi-{Guid.NewGuid():N}";
        return Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        if (string.IsNullOrEmpty(_titel)) return;
        var cs =
            $"Server={Environment.GetEnvironmentVariable("DB_HOST")};Port=3306;" +
            $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
            $"User={Environment.GetEnvironmentVariable("DB_USER")};" +
            $"Password={Environment.GetEnvironmentVariable("DB_PASS")};";
        await using var c = new MySqlConnection(cs);
        await c.OpenAsync();
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "DELETE FROM stellenangebot WHERE titel = @t";
        cmd.Parameters.AddWithValue("@t", _titel);
        await cmd.ExecuteNonQueryAsync();
    }

    [Fact]
    public async Task POST_legt_Stelle_mit_Status_ENTWURF_an()
    {
        using var http = new HttpClient();
        var post = await http.PostAsJsonAsync(Base, new
        {
            titel = _titel,
            art = "WERKSTUDENT",
        });
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);

        var body = JsonDocument.Parse(await post.Content.ReadAsStringAsync()).RootElement;
        Assert.Equal("ENTWURF", body.GetProperty("status").GetString());
        Assert.Equal("WERKSTUDENT", body.GetProperty("art").GetString());
        Assert.True(body.GetProperty("id").GetInt32() > 0);
    }

    [Fact]
    public async Task GET_listet_die_angelegte_Stelle()
    {
        using var http = new HttpClient();
        await http.PostAsJsonAsync(Base, new { titel = _titel, art = "PRAKTIKUM" });

        var res = await http.GetAsync(Base + "?status=ENTWURF");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var list = JsonDocument.Parse(await res.Content.ReadAsStringAsync())
            .RootElement.GetProperty("stellen");
        var titel = list.EnumerateArray()
            .Select(e => e.GetProperty("titel").GetString())
            .ToList();
        Assert.Contains(_titel, titel);
    }

    [Fact]
    public async Task POST_ohne_Titel_liefert_400()
    {
        _titel = string.Empty; // nichts aufzuraeumen
        using var http = new HttpClient();
        var res = await http.PostAsJsonAsync(Base, new { art = "AZUBI" });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        var body = JsonDocument.Parse(await res.Content.ReadAsStringAsync()).RootElement;
        Assert.True(body.TryGetProperty("details", out _));
    }
}
