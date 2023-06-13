# config file for pode api server
@{
    BaseUrl = "/api/v1.0"
    Port = 2306
    Database = "C:\ProgramData\ChocoStatServer\ChocoStatistics.db"

    Server = @{
        Ssl= @{
            Protocols = @('TLS', 'TLS11', 'TLS12')
        }
    }
}
