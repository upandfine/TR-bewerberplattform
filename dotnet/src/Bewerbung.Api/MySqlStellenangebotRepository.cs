using System.Data;
using MySqlConnector;

namespace Bewerbung.Api;

/// <summary>
/// Konkrete Persistenz fuer Stellenangebote gegen MariaDB.
///
/// Alle SQL-Statements nutzen Prepared Statements mit benannten
/// Parametern -> Schutz vor SQL-Injection.
///
/// Spalten in der DB sind camelCase; nach aussen liefern wir stabile
/// snake_case-Schluessel.
/// </summary>
public sealed class MySqlStellenangebotRepository : IStellenangebotRepository
{
    private readonly MySqlConnection _conn;
    private readonly MySqlTransaction? _tx;

    public MySqlStellenangebotRepository(MySqlConnection conn, MySqlTransaction? tx = null)
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

    public async Task<int> InsertStelleAsync(StelleInput s)
    {
        await EnsureOpenAsync();
        using var cmd = CreateCommand(
            "INSERT INTO stellenangebot (titel, beschreibung, art, status) " +
            "VALUES (@titel, @beschreibung, @art, @status)");
        cmd.Parameters.AddWithValue("@titel", s.Titel);
        cmd.Parameters.AddWithValue("@beschreibung", (object?)s.Beschreibung ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@art", s.Art);
        cmd.Parameters.AddWithValue("@status", s.Status);
        await cmd.ExecuteNonQueryAsync();
        return (int)cmd.LastInsertedId;
    }

    public async Task<IReadOnlyList<IDictionary<string, object?>>> ListStellenAsync(
        string? status)
    {
        await EnsureOpenAsync();
        var sql =
            "SELECT id, " +
            "       titel, " +
            "       beschreibung, " +
            "       art, " +
            "       status, " +
            "       erstelltAm        AS erstellt_am, " +
            "       veroeffentlichtAm AS veroeffentlicht_am " +
            "FROM stellenangebot";
        if (status is not null)
        {
            sql += " WHERE status = @status";
        }
        sql += " ORDER BY erstelltAm DESC";

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
