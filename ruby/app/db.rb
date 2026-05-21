require "mysql2"

# Persistenz-Verbindung. Zugangsdaten kommen aus den Umgebungs-
# variablen (DB_HOST/DB_NAME/DB_USER/DB_PASS, aus der .env).
module DB
  def self.connect
    Mysql2::Client.new(
      host:     ENV["DB_HOST"],
      username: ENV["DB_USER"],
      password: ENV["DB_PASS"],
      database: ENV["DB_NAME"],
      encoding: "utf8mb4",
      symbolize_keys: false,
    )
  end
end
