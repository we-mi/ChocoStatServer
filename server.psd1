# config file for pode api server
@{
    BaseUrl = "/api/v1.0"
    Port = 2306
    Database = "C:\ProgramData\ChocoStatServer\ChocoStatistics.db"
    ComputerOverwrite = "write|admin" # can be write or admin or a regex which specifies both. Specifies the type of the needed api-token to overwrite an already available computerobject. 'write' means an user with an api token of type "write" can overwrite any computerobject. If you do not wish that, use 'admin' here.

    Server = @{
        Ssl= @{
            Protocols = @('TLS', 'TLS11', 'TLS12')
        }
    }

    Logging = @{

        Terminal = @{
            Requests = $True
            Errors = $True
        }

        File = @{
            Requests = $True
            Errors = $True
            RequestLog = "ChocoStatServer_Requests"
            ErrorLog = "ChocoStatServer_Error"
            DebugLog = "ChocoStatServer_Debug"
        }

        EventViewer = @{
            Requests = $True
            Errors = $True
            EventLogName = "ChocoStatServer"
            RequestSource = "ChocoStatServer_Requests"
            ErrorSource = "ChocoStatServer_Error"
            DebugSource = "ChocoStatServer_Debug"
        }
    }
}
