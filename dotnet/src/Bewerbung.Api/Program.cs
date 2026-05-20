using System.Text.Json;
using Bewerbung.Api;
using MySqlConnector;

var builder = WebApplication.CreateBuilder(args);

// JSON: snake_case rein und raus (gleicher Vertrag wie PHP/Python/Node)
builder.Services.Configure<Microsoft.AspNetCore.Http.Json.JsonOptions>(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
});

// DI: pro Request eine MySqlConnection (Pooling übernimmt MySqlConnector)
builder.Services.AddScoped(_ =>
{
    var cs =
        $"Server={Environment.GetEnvironmentVariable("DB_HOST")};Port=3306;" +
        $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
        $"User={Environment.GetEnvironmentVariable("DB_USER")};" +
        $"Password={Environment.GetEnvironmentVariable("DB_PASS")};";
    return new MySqlConnection(cs);
});
builder.Services.AddScoped<IBewerbungRepository>(sp =>
    new MySqlBewerbungRepository(sp.GetRequiredService<MySqlConnection>()));
builder.Services.AddScoped<BewerbungService>();

// CORS: erlaubt dem Vue-Frontend (anderer Origin) den Zugriff.
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();

app.UseCors();

app.MapGet("/", () => Results.Content(
    "<h1>ASP.NET Core läuft</h1><p>API unter /api/bewerbungen</p>",
    "text/html; charset=utf-8"));

app.MapPost("/api/bewerbungen", async (BewerbungInput input, BewerbungService svc) =>
{
    try
    {
        var result = await svc.EinreichenAsync(input);
        return Results.Json(result, statusCode: 201);
    }
    catch (ValidationException ex)
    {
        return Results.Json(
            new { fehler = ex.Message, details = ex.Errors },
            statusCode: 400);
    }
    catch (MySqlException ex) when (ex.Number == 1452)
    {
        return Results.Json(
            new { fehler = "Angegebene stelle_id existiert nicht." },
            statusCode: 422);
    }
    catch (MySqlException ex) when (ex.Number == 1062)
    {
        return Results.Json(
            new { fehler = "Vorgangsnummer-Kollision, bitte erneut senden." },
            statusCode: 409);
    }
    catch (MySqlException)
    {
        return Results.Json(new { fehler = "Datenbankfehler." }, statusCode: 500);
    }
});

app.MapGet("/api/bewerbungen", async (string? status, BewerbungService svc) =>
{
    var liste = await svc.ListeAsync(status);
    return Results.Json(new { bewerbungen = liste });
});

app.Run();

// Wird vom Test-Projekt (WebApplicationFactory) referenziert
public partial class Program;
