using System.Data;
using MySqlConnector;

namespace Bewerbung.Api;

/// <summary>
/// Konkrete Persistenz gegen MariaDB. Integration-testbar gegen die
/// laufende DB (FK-RESTRICT auf Stelle, UNIQUE vorgangsNr).
///
/// Spalten in der DB sind camelCase; nach außen liefern wir stabile
/// snake_case-Schlüssel (gleicher Vertrag wie PHP/Python/Node).
///
/// Eine optionale Transaktion macht das Repository in Tests sauber
/// per Rollback nutzbar, ohne die Produktivnutzung zu verkomplizieren.
/// </summary>
public sealed class MySqlBewerbungRepository : IBewerbungRepository
{
    private readonly MySqlConnection _conn;
    private readonly MySqlTransaction? _tx;

    public MySqlBewerbungRepository(MySqlConnection conn, MySqlTransaction? tx = null)
    {
        _conn = conn;
        _tx = tx;
    }

    private async Task EnsureOpenAsync()
    {
        if (_conn.State != ConnectionState.Open)
        {
            await _conn.OpenAsync();
        }
    }

    private MySqlCommand CreateCommand(string sql)
    {
        var cmd = _conn.CreateCommand();
        cmd.CommandText = sql;
        if (_tx is not null)
        {
            cmd.Transaction = _tx;
        }
        return cmd;
    }

    public async Task<int?> FindBewerberIdByEmailAsync(string email)
    {
        await EnsureOpenAsync();
        using var cmd = CreateCommand("SELECT id FROM bewerber WHERE email = @email");
        cmd.Parameters.AddWithValue("@email", email);
        var result = await cmd.ExecuteScalarAsync();
        return result is null or DBNull ? null : Convert.ToInt32(result);
    }

    public async Task<int> InsertBewerberAsync(BewerberInput b)
    {
        await EnsureOpenAsync();
        using var cmd = CreateCommand(
            "INSERT INTO bewerber (vorname, nachname, email, telefon) " +
            "VALUES (@vorname, @nachname, @email, @telefon)");
        cmd.Parameters.AddWithValue("@vorname", b.Vorname);
        cmd.Parameters.AddWithValue("@nachname", b.Nachname);
        cmd.Parameters.AddWithValue("@email", b.Email);
        cmd.Parameters.AddWithValue("@telefon", (object?)b.Telefon ?? DBNull.Value);
        await cmd.ExecuteNonQueryAsync();
        return (int)cmd.LastInsertedId;
    }

    public async Task<int> InsertBewerbungAsync(
        int bewerberId, int stelleId, string vorgangsNr, string? bemerkung)
    {
        await EnsureOpenAsync();
        using var cmd = CreateCommand(
            "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) " +
            "VALUES (@bewerberId, @stelleId, @vorgangsNr, @bemerkung)");
        cmd.Parameters.AddWithValue("@bewerberId", bewerberId);
        cmd.Parameters.AddWithValue("@stelleId", stelleId);
        cmd.Parameters.AddWithValue("@vorgangsNr", vorgangsNr);
        cmd.Parameters.AddWithValue("@bemerkung", (object?)bemerkung ?? DBNull.Value);
        await cmd.ExecuteNonQueryAsync();
        return (int)cmd.LastInsertedId;
    }

    public async Task<IReadOnlyList<IDictionary<string, object?>>> ListBewerbungenAsync(
        string? status)
    {
        await EnsureOpenAsync();
        var sql =
            "SELECT b.id, " +
            "       b.vorgangsNr AS vorgangs_nr, " +
            "       b.status, " +
            "       b.eingangAm  AS eingang_am, " +
            "       bw.vorname, bw.nachname, bw.email, " +
            "       s.titel AS stelle " +
            "FROM bewerbung b " +
            "JOIN bewerber bw      ON bw.id = b.bewerberId " +
            "JOIN stellenangebot s ON s.id  = b.stelleId";
        if (status is not null)
        {
            sql += " WHERE b.status = @status";
        }
        sql += " ORDER BY b.eingangAm DESC";

        using var cmd = CreateCommand(sql);
        if (status is not null)
        {
            cmd.Parameters.AddWithValue("@status", status);
        }

        var list = new List<IDictionary<string, object?>>();
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object?>();
            for (var i = 0; i < reader.FieldCount; i++)
            {
                var name = reader.GetName(i);
                var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                // DateTime einheitlich wie in PHP-Ausgabe formatieren
                if (value is DateTime dt)
                {
                    value = dt.ToString("yyyy-MM-dd HH:mm:ss");
                }
                row[name] = value;
            }
            list.Add(row);
        }
        return list;
    }
}
