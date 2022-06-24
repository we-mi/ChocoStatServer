Write-Verbose 'Importing from [C:\projects\restps\RestPS\private]'
# .\RestPS\private\Get-ClientCertInfo.ps1

function Convert-HTTPParamsToObject {
    <#
    .SYNOPSIS
        Converts URI-Parameters to an powershell object array
    .DESCRIPTION
        It takes only the request parameters as the argument, not the full URI. See examples.
    .EXAMPLE
        Get-RequestArgs -Query "ID=50&Name=foo"
        Will return this object:
            Param Value
            ----- -----
            ID    50  
            Name  foo
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        # GET-Parameters as written in the URI, like 'ID=50&Name=foo'
        [Parameter()]
        [AllowEmptyString()]
        [String]$GETParams,

        # POST-Parameters as a json-formatted-string
        [Parameter()]
        [AllowEmptyString()]
        [String]$POSTParams

    )

    process {
        $result = @{}

        # Parse POST-Params (has precedence over GET-Params) (has no effect on GET-Method)
        if ($null -ne $POSTParams -and -not [String]::IsNullOrWhiteSpace($POSTParams) -and $POSTParams -ne "null") {
            $JSON = $POSTParams | ConvertFrom-Json
            
            foreach ($key in ($JSON | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) ) {
                if ($result.Keys -notcontains $key) {
                    $result.$Key = $JSON.$Key
                }
            }
        }

        # Parse GET-Params
        if ($null -ne $GETParams -and -not [String]::IsNullOrWhiteSpace($GETParams) ) {
            $ParsedQueryString = [System.Web.HttpUtility]::ParseQueryString($GETParams)

            for($i = 0; $i -lt $ParsedQueryString.Count; $i++) {
                $key = $ParsedQueryString.AllKeys[$i]
                if ($result.Keys -notcontains $key) {
                    $result.$key = $ParsedQueryString[$i]
                }
            }
        }

        $result
    }
}

function Get-ClientCertInfo
{
    <#
	.DESCRIPTION
		This function Collect Information on a Client Certificate.
	.EXAMPLE
        Get-ClientCertInfo
	.NOTES
        This will return null.
    #>
    $script:ClientCert = $script:Request.GetClientCertificate()
    $script:SubjectName = $script:ClientCert.Subject
}
# .\RestPS\private\Import-RouteSet.ps1
function Import-RouteSet
{
    <#
	.DESCRIPTION
		This function imports the specified routes file.
    .PARAMETER RoutesFilePath
        Provide a valid path to a .json file
    .EXAMPLE
        Invoke-AvailableRouteSet -RoutesFilePath $env:systemdrive/RestPS/endpoints/routes.json
	.NOTES
        This will return null.
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]

    param(
        [Parameter(Mandatory = $true)][String]$RoutesFilePath
    )

    if (Test-Path -Path $RoutesFilePath)
    {
        $script:Routes = Get-Content -Raw $RoutesFilePath | ConvertFrom-Json
    }
    else
    {
        Throw "Import-RouteSet - Could not validate Path $RoutesFilePath"
    }
}
# .\RestPS\private\Invoke-GetBody.ps1
function Invoke-GetBody
{
    <#
	.DESCRIPTION
		This function retrieves the Data from the HTTP Listener Body property.
	.EXAMPLE
        Invoke-GetBody
	.NOTES
        This will return a Body object.
    #>
    if ($script:Request.HasEntityBody)
    {
        $script:RawBody = $script:Request.InputStream
        $Reader = New-Object System.IO.StreamReader @($script:RawBody, [System.Text.Encoding]::UTF8)
        $script:Body = $Reader.ReadToEnd()
        $Reader.close()
        $script:Body
    }
    else
    {
        $script:Body = "null"
        $script:Body
    }
}
# .\RestPS\private\Invoke-GetContext.ps1
function Invoke-GetContext
{
    <#
	.DESCRIPTION
		This function retrieves the Data from the HTTP Listener.
	.EXAMPLE
        Invoke-GetContext
	.NOTES
        This will return a HTTPListenerContext object.
    #>
    $script:context = $listener.GetContext()
    $Request = $script:context.Request
    $Request
}
# .\RestPS\private\Invoke-RequestRouter.ps1
function Invoke-RequestRouter
{
    <#
    .DESCRIPTION
	This function will attempt to run a Client specified command defined in the Endpoint Routes.
    .PARAMETER RequestType
        A RequestType is required.
    .PARAMETER RequestURL
        A RequestURL is is required.
    .PARAMETER RequestArgs
        A RequestArgs is Optional.
    .PARAMETER RoutesFilePath
        A RoutesFilePath is Optional.
	.EXAMPLE
        Invoke-RequestRouter -RequestType GET -RequestURL /process
	.EXAMPLE
        Invoke-RequestRouter -RequestType GET -RequestURL /process -RoutesFilePath $env:systemdrive/RestPS/endpoints/routes.json
	.EXAMPLE
        Invoke-RequestRouter -RequestType GET -RequestURL /process -RoutesFilePath $env:systemdrive/RestPS/endpoints/routes.json -RequestArgs foo=Bar&cash=Money
	.NOTES
        This will return output from the Endpoint Command/script.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", '')]
    [OutputType([boolean])]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory = $true)][String]$RequestType,
        [Parameter(Mandatory = $true)][String]$RequestURL,
        [Parameter(Mandatory = $false)][String]$RequestArgs,
        [Parameter()][String]$RoutesFilePath
    )
    # Import Routes each pass, to include new routes.
    #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Importing RouteSet"
    Import-RouteSet -RoutesFilePath $RoutesFilePath
    $Route = ($Routes | Where-Object { $_.RequestType -eq $RequestType -and ($RequestURL -match $_.RequestURL -or $RequestURL -eq $_.RequestURL) } )
    
    # Set the value of the $script:StatusDescription and $script:StatusCode to null from previous runs.
    $script:StatusDescription = $null
    $script:StatusCode = $null

    if ($Route.Count -gt 1) {
        # Too many matching Routes
        #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Too many Matching routes (400)."
        $script:StatusDescription = "Too many Routes found"
        $script:StatusCode = "400"
    } elseif ($null -ne $Route) {
        # Process Request
        $RequestCommand = $Route.RequestCommand

        if ($matches.Count -gt 0) {
            $varRouteValue = $matches[1]
        } else {
            $varRouteValue = $null
        }

        # Grab non-default ResponseContentType for the route:
        $script:ResponseContentType = $Route.ResponseContentType

        set-location $PSScriptRoot
        if ($RequestCommand -like "*.ps1")
        {
            # Execute Endpoint Script
            #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Executing Endpoint Script."
            if ($null -ne $varRouteValue) {
                $CommandReturn = . $RequestCommand -RequestArgs $RequestArgs -Body $script:Body -VarRouteValue $varRouteValue
            } else {
                $CommandReturn = . $RequestCommand -RequestArgs $RequestArgs -Body $script:Body
            }
        }
        else
        {
            # Execute Endpoint Command (No body allowed.)
            #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Executing Endpoint Command."
            $Command = $RequestCommand + " " + $RequestArgs
            $CommandReturn = Invoke-Expression -Command "$Command" -ErrorAction SilentlyContinue
        }

        if ($null -eq $CommandReturn)
        {
            # Not a valid response
            #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Bad Request (400)."
            if ($null -eq $script:StatusDescription)
            {
                $script:StatusDescription = "Bad Request"
            }
            if ($null -eq $script:StatusCode)
            {
                $script:StatusCode = 400
            }
        }
        else
        {
            # Valid response
            #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: Valid Response (200)."
            $script:result = $CommandReturn
            if ($null -eq $script:StatusDescription)
            {
                $script:StatusDescription = "OK"
            }
            if ($null -eq $script:StatusCode)
            {
                $script:StatusCode = 200
            }
        }
    } else {
        # No matching Routes
        #Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-RequestRouter: No Matching routes (404)."
        $script:StatusDescription = "Not Found"
        $script:StatusCode = 404
        $script:Result = @{type = "error"; errormsg = "Ressource not found" }
    }
    $script:result
}

# .\RestPS\private\Invoke-StartListener.ps1
function Invoke-StartListener
{
    <#
	.DESCRIPTION
		This function will start a defined HTTP listener.
    .PARAMETER Port
        A Port is required.
    .PARAMETER SSLThumbprint
        An SSLThumbprint is optional.
    .PARAMETER AppGuid
        A AppGuid is Optional.
	.EXAMPLE
        Invoke-StartListener -Port 8080
	.EXAMPLE
        Invoke-StartListener -Port 8080 -SSLThumbPrint $SSLThumbPrint -AppGuid $AppGuid
	.NOTES
        This will return null.
    #>
    param(
        [Parameter(Mandatory = $true)][String]$Port,
        [Parameter()][String]$SSLThumbprint,
        [Parameter()][String]$AppGuid
    )
    if ($SSLThumbprint)
    {
        # Verify the Certificate with the Specified Thumbprint is available.
        $CertificateListCount = ((Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object {$_.Thumbprint -eq "$SSLThumbprint"}) | Measure-Object).Count
        if ($CertificateListCount -ne 0)
        {
            # SSL Thumbprint present, enabling SSL
            netsh http delete sslcert ipport=0.0.0.0:$Port
            netsh http add sslcert ipport=0.0.0.0:$Port certhash=$SSLThumbprint "appid={$AppGuid}"
            $Prefix = "https://"
        }
        else
        {
            Throw "Invoke-StartListener: Could not find Matching Certificate in CertStore: Cert:\LocalMachine"
        }
    }
    else
    {
        # No SSL Thumbprint present
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Invoke-StartListener: No SSL Thumbprint present"
        $Prefix = "http://"
    }
    try
    {
        $listener.Prefixes.Add("$Prefix+:$Port/")
        $listener.Start()
        $Host.UI.RawUI.WindowTitle = "RestPS - $Prefix - Port: $Port"
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-StartListener: Starting: $Prefix Listener on Port: $Port"
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Invoke-StartListener: $ErrorMessage $FailedItem"
    }
}
# .\RestPS\private\Invoke-StopListener.ps1
function Invoke-StopListener
{
    <#
	.DESCRIPTION
		This function will stop the specified Http(s) Listener.
    .PARAMETER Port
        A Port is Optional. Defaults to 8080.
	.EXAMPLE
        Invoke-StopListener -Port 8080
	.EXAMPLE
        Invoke-StopListener
	.NOTES
        This will return Null.
    #>
    param(
        [Parameter()][String]$Port = 8080
    )
    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-StopListener: Stopping HTTP Listener on port: $Port ..."
    $listener.Stop()
}
# .\RestPS\private\Invoke-StreamOutput.ps1
function Invoke-StreamOutput
{
    <#
	.DESCRIPTION
        This function will Stream output back to the Client.
	.EXAMPLE
        Invoke-StreamOutput
	.NOTES
        This will returns a stream of data. And compress data if needed.
    #>
    # Setup a placeholder to deliver a response
    $script:Response = $script:context.Response

    if ($null -eq $script:ResponseContentType)
    {
        # If a response content type hasn't been defined in RestPSRoutes.json then default to JSON
        $script:Response.ContentType = 'application/json'

        # Process the Return data to send Json message back.
        $message = $script:result | ConvertTo-Json -Depth 10
    }
    else
    {
        # Set the content type to that defined in RestPSRoutes.json (e.g. text/plain)
        $script:Response.ContentType = $script:ResponseContentType

        # Process the return data to send back as plain text
        $message = $script:result
    }
    $script:Response.StatusCode = $script:StatusCode
    $script:Response.StatusDescription = $script:StatusDescription

    $responseByteArray = [byte[]][System.Text.Encoding]::UTF8.GetBytes("$message")
    try
    {
        if ($context.Request.Headers.Item('Accept-Encoding').Split(",").ToLowerInvariant() -contains "gzip")
        {
            # This part is strictly speaking not entirely RFC compliant.
            # it would need to handle qvalues as well:
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding#:~:text=The%20Accept%2DEncoding%20request%20HTTP,the%20Content%2DEncoding%20response%20header.

            # Compress output
            # https://stackoverflow.com/questions/7438217/c-sharp-httplistener-response-gzipstream

            # compress responseByteArray and save back to responseByteArray
            $memoryStream = [System.IO.MemoryStream]::new()
            $gzipStream = [System.IO.Compression.GZipStream]::new($memoryStream, [System.IO.Compression.CompressionMode]::Compress, $true)
            $gzipStream.Write($responseByteArray, 0, $responseByteArray.Length)
            $gzipStream.Close()
            $responseByteArray = $memoryStream.ToArray()

            # Add some headers
            $Script:Response.SendChunked = $true
            $script:Response.AddHeader("Content-Encoding", "gzip");
        }
        else
        {
            # Do not compress output
        }
    }
    Catch
    {
        # Do not compress output
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        "Invoke-DeployRestPS: $ErrorMessage $FailedItem" | Out-Null
    }

    $script:Response.ContentLength64 = $responseByteArray.length
    $script:Response.OutputStream.Write($responseByteArray, 0, $responseByteArray.length)

    $script:Response.Close()
}

# .\RestPS\private\Invoke-ValidateClient.ps1
function Invoke-ValidateClient
{
    <#
    .DESCRIPTION
        This function provides several way to validate or authenticate a client. A client
        could be a user or a computer.
    .PARAMETER VerificationType
        A VerificationType is optional - Accepted values are:
            -"VerifyRootCA": Verifies the Root CA of the Server and Client Cert Match.
            -"VerifySubject": Verifies the Root CA, and the Client is on a User provide ACL.
            -"VerifyUserAuth": Provides an option for Advanced Authentication, plus the RootCA,Subject Checks.
    .PARAMETER RestPSLocalRoot
        The RestPSLocalRoot is also optional, and defaults to "C:\RestPS"
    .EXAMPLE
        Invoke-ValidateClient -VerificationType VerifyRootCA -RestPSLocalRoot c:\RestPS
    .NOTES
        This will return a boolean.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [ValidateSet("VerifyRootCA", "VerifySubject", "VerifyUserAuth","VerifyBasicAuth")]
        [Parameter()][String]$VerificationType,
        [Parameter()][String]$RestPSLocalRoot = "c:\RestPS"
    )
    switch ($VerificationType)
    {
        "VerifyRootCA"
        {
            # Source the File
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Gathering Client Cert Info"
            Get-ClientCertInfo
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Validating Client CN: $script:SubjectName"
            . $RestPSLocalRoot\bin\Invoke-VerifyRootCA.ps1
            $script:VerifyStatus = Invoke-VerifyRootCA
        }

        "VerifySubject"
        {
            # Source the File
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Gathering Client Cert Info"
            Get-ClientCertInfo
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Validating Client CN: $script:SubjectName"
            . $RestPSLocalRoot\bin\Invoke-VerifySubject.ps1
            $script:VerifyStatus = Invoke-VerifySubject
        }

        "VerifyUserAuth"
        {
            # Source the File
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Gathering Client Cert Info"
            Get-ClientCertInfo
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Validating Client CN: $script:SubjectName"
            . $RestPSLocalRoot\bin\Invoke-VerifyUserAuth.ps1
            $script:VerifyStatus = Invoke-VerifyUserAuth
        }

        "VerifyBasicAuth"
        {
            # Source the File
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: Validating Basic Auth"
            . $RestPSLocalRoot\bin\Invoke-VerifyBasicAuth.ps1
            $script:VerifyStatus = Invoke-VerifyBasicAuth
        }

        default
        {
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateClient: No Client Validation Selected."
            $script:VerifyStatus = $true
        }
    }
    $script:VerifyStatus
}

# .\RestPS\private\Invoke-ValidateIP.ps1
function Invoke-ValidateIP
{
    <#
    .DESCRIPTION
        This function provides several way to validate or authenticate a client base on acceptable IP's.
    .PARAMETER RestPSLocalRoot
        The RestPSLocalRoot is also optional, and defaults to "C:\RestPS"
    .PARAMETER VerifyClientIP
        A VerifyClientIP is optional - Accepted values are:$false or $true
    .EXAMPLE
        Invoke-ValidateIP -VerifyClientIP $true -RestPSLocalRoot c:\RestPS
    .NOTES
        This will return a boolean.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter()][String]$RestPSLocalRoot = "c:\RestPS",
        [Parameter()][Bool]$VerifyClientIP
    )
    if ($VerifyClientIP -eq $true)
    {
        . $RestPSLocalRoot\bin\Get-RestIPAuth.ps1
        $RestIPAuth = (Get-RestIPAuth).UserIP
        $RequesterIP = $script:Request.RemoteEndPoint
        if ($null -ne $RestIPAuth)
        {
            $RequesterIP, $RequesterPort = $RequesterIP -split (":")
            $RequesterStatus = $RestIPAuth | Where-Object {($_.IP -eq "$RequesterIP")}
            if (($RequesterStatus | Measure-Object).Count -eq 1)
            {
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-ValidateIP: Valid Client IP"
                $script:VerifyStatus = $true
            }
            else
            {
                $script:VerifyStatus = $false
            }
        }
        else
        {
            $script:VerifyStatus = $false
        }
    }
    $script:VerifyStatus
}

Write-Verbose 'Importing from [C:\projects\restps\RestPS\public]'
# .\RestPS\public\Disable-SSLValidation.ps1
function Disable-SSLValidation
{
    <#
    .SYNOPSIS
        Disables SSL certificate validation
    .DESCRIPTION
        Disable-SSLValidation disables SSL certificate validation by using reflection to implement the System.Net.ICertificatePolicy class.
        Author: Matthew Graeber (@mattifestation)
        License: BSD 3-Clause
    .NOTES
        Reflection is ideal in situations when a script executes in an environment in which you cannot call csc.ese to compile source code.
        If compiling code is an option, then implementing System.Net.ICertificatePolicy in C# and Add-Type is trivial.
    .EXAMPLE
        Disable-SSLValidation
    .LINK
        http://www.exploit-monday.com
    #>
    Set-StrictMode -Version 2
    # You have already run this function if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -eq 'IgnoreCerts') { Return }
    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
    $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
    $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
    $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | ForEach-Object {$_.ParameterType})))
    $ILGen = $MethodBuilder.GetILGenerator()
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
    $TypeBuilder.CreateType() | Out-Null

    # Disable SSL certificate validation
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
    return $true
}
# .\RestPS\public\Invoke-DeployRestPS.ps1
function Invoke-DeployRestPS
{
    <#
	.DESCRIPTION
		This function will setup a local Endpoint directory structure.
    .PARAMETER LocalDir
        A LocalDir is Optional.
    .PARAMETER SourceDir
        An install directory of the Module, if Get-Module will not find it, is Optional.
    .PARAMETER Logfile
        Full path to a logfile for RestPS messages to be written to.
    .PARAMETER LogLevel
        Level of verbosity of logging for the runtime environment. Default is 'INFO' See PowerLumber Module for details.
    .EXAMPLE
        Invoke-DeployRestPS -LocalDir $env:SystemDrive/RestPS
    .NOTES
        This will return a boolean.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [string]$LocalDir = "$env:SystemDrive/RestPS",
        [string]$SourceDir = (Split-Path -Path (Get-Module -ListAvailable RestPS | Sort-Object -Property Version -Descending | Select-Object -First 1).path),
	[String]$Logfile = "$env:SystemDrive/RestPS/RestPS.log",
	[String]$LogLevel = "INFO"
    )
    try
    {
        # Setup the local File directories
        if (Test-Path -Path "$LocalDir")
        {
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-DeployRestPS: Directory: $localDir, exists."
        }
        else
        {
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-DeployRestPS: Creating RestPS Directories."
            New-Item -Path "$LocalDir" -ItemType Directory
            New-Item -Path "$LocalDir/bin" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints/Logs" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints/GET" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints/POST" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints/PUT" -ItemType Directory
            New-Item -Path "$LocalDir/endpoints/DELETE" -ItemType Directory
        }
        # Move Example files to the Local Directory
        $RoutesFileSource = $SourceDir + "/endpoints/RestPSRoutes.json"
        Copy-Item -Path "$RoutesFileSource" -Destination "$LocalDir/endpoints" -Confirm:$false -Force
        $GetRoutesFileSource = $SourceDir + "/endpoints/GET/Invoke-GetRoutes.ps1"
        Copy-Item -Path $GetRoutesFileSource -Destination "$LocalDir/endpoints/GET" -Confirm:$false -Force
        $EndpointVerbs = @("GET", "POST", "PUT", "DELETE")
        foreach ($Verb in $EndpointVerbs)
        {
            $endpointsource = $SourceDir + "/endpoints/$Verb/Invoke-GetProcess.ps1"
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-DeployRestPS: Copying $endpointsource to Desination $LocalDir/endpoints/$Verb"
            Copy-Item -Path "$endpointsource" -Destination "$LocalDir/endpoints/$Verb" -Confirm:$false -Force
        }
        $BinFiles = Get-ChildItem -Path ($SourceDir + "/bin") -File
        foreach ($file in $BinFiles)
        {
            $filePath = $file.FullName
            $filename = $file.Name
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Invoke-DeployRestPS: Copying File $fileName to $localDir/bin"
            Copy-Item -Path "$filePath" -Destination "$LocalDir/bin" -Confirm:$false -Force
        }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Throw "Invoke-DeployRestPS: $ErrorMessage $FailedItem"
    }
}

# .\RestPS\public\Start-RestPSListener.ps1
function Start-RestPSListener
{
    <#
    .DESCRIPTION
        Start a HTTP listener on a specified port.
    .PARAMETER Port
        A Port can be specified, but is not required, Default is 8080.
    .PARAMETER SSLThumbprint
        A SSLThumbprint can be specified, but is not required.
    .PARAMETER RestPSLocalRoot
        A RestPSLocalRoot be specified, but is not required. Default is c:\RestPS
    .PARAMETER AppGuid
        A AppGuid can be specified, but is not required.
    .PARAMETER VerificationType
        A VerificationType is optional - Accepted values are:
            -"VerifyRootCA": Verifies the Root CA of the Server and Client Cert Match.
            -"VerifySubject": Verifies the Root CA, and the Client is on a User provide ACL.
            -"VerifyUserAuth": Provides an option for Advanced Authentication, plus the RootCA,Subject Checks.
            -"VerifyBasicAuth": Provides an option for Basic Authentication.
    .PARAMETER RoutesFilePath
        A Custom Routes file can be specified, but is not required, default is included in the module.
    .PARAMETER Logfile
        Full path to a logfile for RestPS messages to be written to.
    .PARAMETER LogLevel
        Level of verbosity of logging for the runtime environment. Default is 'INFO' See PowerLumber Module for details.
    .PARAMETER VerifyClientIP
        Validate client IP authorization. (Default=$false) to enable set $true
    .EXAMPLE
        Start-RestPSListener
    .EXAMPLE
        Start-RestPSListener -Port 8081
    .EXAMPLE
        Start-RestPSListener -Port 8081 -Logfile "c:\RestPS\RestPS.log" -LogLevel TRACE
    .EXAMPLE
        Start-RestPSListener -Port 8081 -Logfile "c:\RestPS\RestPS.log" -LogLevel INFO
    .EXAMPLE
        Start-RestPSListener -Port 8081 -RoutesFilePath $env:SystemDrive/RestPS/temp/customRoutes.ps1
    .EXAMPLE
        Start-RestPSListener -RoutesFilePath $env:SystemDrive/RestPS/customRoutes.ps1
    .EXAMPLE
        Start-RestPSListener -RoutesFilePath $env:SystemDrive/RestPS/customRoutes.ps1 -VerificationType VerifyRootCA -SSLThumbprint $Thumb -AppGuid $Guid
    .NOTES
        No notes at this time.
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Low"
    )]
    [OutputType([boolean])]
    [OutputType([Hashtable])]
    [OutputType([String])]
    param(
        [Parameter()][String]$RoutesFilePath = "$env:SystemDrive/RestPS/endpoints/RestPSRoutes.json",
        [Parameter()][String]$RestPSLocalRoot = "$env:SystemDrive/RestPS",
        [Parameter()][String]$Port = 8080,
        [Parameter()][String]$SSLThumbprint,
        [Parameter()][String]$AppGuid = ((New-Guid).Guid),
        [ValidateSet("VerifyRootCA", "VerifySubject", "VerifyUserAuth","VerifyBasicAuth")]
        [Parameter()][String]$VerificationType,
        [Parameter()][String]$Logfile = "$env:SystemDrive/RestPS/RestPS.log",
        [ValidateSet("ALL", "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "CONSOLEONLY", "OFF")]
        [Parameter()][String]$LogLevel = "INFO",
        [Parameter()][Bool]$VerifyClientIP = $false
    )
    # Set a few Flags
    $script:Status = $true
    $script:ValidateClient = $true
    if ($pscmdlet.ShouldProcess("Starting .Net.HttpListener."))
    {
        $script:listener = New-Object System.Net.HttpListener
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Calling Invoke-StartListener"
        Invoke-StartListener -Port $Port -SSLThumbPrint $SSLThumbprint -AppGuid $AppGuid
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Finished Calling Invoke-StartListener"
        # Run until you send a GET request to /shutdown
        Do
        {
            # Capture requests as they come in (not Asyncronous)
            # Routes can be configured to be Asyncronous in Nature.
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Captured incoming request"
            $script:Request = Invoke-GetContext
            $script:ProcessRequest = $true
            $script:result = $null

            # Perform Client Verification if SSLThumbprint is present and a Verification Method is specified.
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Determining VerificationType: '$VerificationType'"
            if ($VerificationType -ne "" -or $VerifyClientIP -eq $true)
            {
                # Validate client IP authorization.
                if ($VerifyClientIP -eq $true)
                {
                    # Start validation of client IP's.
                    if($VerificationType -eq "")
                    {
                        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-ValidateIP Validate IP only"
                        $script:ProcessRequest = (Invoke-ValidateIP -RestPSLocalRoot $RestPSLocalRoot -VerifyClientIP $VerifyClientIP)
                    }
                    # Validate client IP's and VerificationType.
                    else
                    {
                        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-ValidateIP Validate IP before Authentication"
                        $script:ProcessRequest = (Invoke-ValidateIP -RestPSLocalRoot $RestPSLocalRoot -VerifyClientIP $VerifyClientIP)
                        # Determine if client IP validation was successful then start validation of VerificationType.
                        if ($script:ProcessRequest -eq $true)
                        {
                            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-ValidateIP Validate Authentication Type"
                            $script:ProcessRequest = (Invoke-ValidateClient -VerificationType $VerificationType -RestPSLocalRoot $RestPSLocalRoot)
                        }
                    }
                }
                else
                {
                    # Validate only verification type.
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-ValidateClient"
                    $script:ProcessRequest = (Invoke-ValidateClient -VerificationType $VerificationType -RestPSLocalRoot $RestPSLocalRoot)
                }
            }
            else
            {
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: NOT Executing Invoke-ValidateClient"
                $script:ProcessRequest = $true
            }

            # Determine if a Body was sent with the Client request
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Executing Invoke-GetBody"
            $script:Body = Invoke-GetBody

            # Request Handler Data
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Determining Method and URL"
            $RequestType = $script:Request.HttpMethod
            $RawRequestURL = $script:Request.RawUrl
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: New Request - Method: $RequestType URL: $RawRequestURL"
            # Specific args will need to be parsed in the Route commands/scripts
            $RequestURL, $RequestArgs = $RawRequestURL.split("?")

            if ($script:ProcessRequest -eq $true)
            {
                # Break from loop if GET request sent to /shutdown
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Processing Request, Checking for Shutdown Command"
                if ($RequestURL -match '/EndPoint/Shutdown$')
                {
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Shutting down RestEndpoint"
                    $script:result = "Shutting down RESTPS Endpoint."
                    $script:Status = $false
                    $script:StatusCode = 200
                }
                else
                {
                    # Attempt to process the Request.
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
                    $script:result = Invoke-RequestRouter -RequestType "$RequestType" -RequestURL "$RequestURL" -RoutesFilePath "$RoutesFilePath" -RequestArgs "$RequestArgs"
                    Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Finished request. StatusCode: $script:StatusCode StatusDesc: $Script:StatusDescription"
                }
            }
            else
            {
                Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType INFO -Message "Start-RestPSListener: Unauthorized (401) NOT Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
                $script:StatusDescription = "Unauthorized"
                $script:StatusCode = 401
            }
            # Stream the output back to requestor.
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Streaming response back to requestor."
            Invoke-StreamOutput
            Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Streaming response is complete."
        } while ($script:Status -eq $true)
        #Terminate the listener
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Stopping Listener."
        Invoke-StopListener -Port $Port
        Write-Log -LogFile $Logfile -LogLevel $logLevel -MsgType TRACE -Message "Start-RestPSListener: Listener Stopped."
    }
    else
    {
        # -WhatIf was used.
        return $false
    }
}

Write-Verbose 'Importing from [C:\projects\restps\RestPS\classes]'

