<#
.SYNOPSIS
    Modified version of windows installer for AWS sytems manager
.NOTES
    Version:        1.6
    Authors:        Justin Harris, Joshua Hiller

#>
[CmdletBinding()]
param(
    [Parameter(HelpMessage="Falcon API Client ID")]
    [string]$FalconClientId = "",
    [Parameter(HelpMessage="Falcon API Client Secret")]
    [string]$FalconClientSecret = "",
    [Parameter(HelpMessage="Falcon CID")]
    [string]$FalconClientCID = "",
    [Parameter(HelpMessage="Authorization Token")]
    [string]$CSAuthToken = ""
)
begin {
    <# USER CONFIG ###############################################################################>

    ## OAuth 2 API Client/Secret
    # Permissions required: sensor-installers:read, sensor-update-policies:read (if defining $PolicyName)
    
    $InstallParams = @(
    , '/install'
    , '/quiet'
    , '/norestart'
    , "CID=$FalconClientCID"
    , 'ProvWaitTime=1200000'
    , "ProvToken=$CSAuthToken"
)

    [string] $ApiClient = "$FalconClientId"
    [string] $ApiSecret = "$FalconSecret"

    ## 'Member CID' if working in MSSP or Parent/Child CID environments. Default: $null.
    [string] $MemberCID = $null

    ## API Host
    # EU-1     : 'https://api.eu-1.crowdstrike.com'
    # GovCloud : 'https://api.laggar.gcw.crowdstrike.com'
    # US-1     : 'https://api.crowdstrike.com'
    # US-2     : 'https://api.us-2.crowdstrike.com'
    [string] $ApiHost = 'https://api.crowdstrike.com'

    ## Installer Options

    # The policy name to check to find which version to install. If defining a specific
    # version or using the newest version, input $null. If using 'Default (<OS>)', input 'platform_default'.
    [string] $PolicyName = $null

    # A specific version to install. If checking a policy or using the newest version, input $null.
    [string] $Version = $null

    # Installation parameters beyond '/install', '/quiet', '/noreboot' and 'CCID='. If no
    # additional parameters are required, input $null.

    [string] $InstallParams = '/install CCID='${CCID}

    # Input `$true` or `$false` to delete the script and/or installer after installation.
    [boolean] $DeleteInstaller = $true
    [boolean] $DeleteScript = $true

    <############################################################################### USER CONFIG #>

    # Regex pattern for finding build from /policy/combined/sensor-update/v2
    [regex] $BuildRegex = '^\d*'

    # Create 'PSFalcon' Windows Event Log, if not present
    if (-not([System.Diagnostics.EventLog]::SourceExists('PSFalcon'))) {
        New-EventLog -LogName PSFalcon -Source PSFalcon
    }
    # Basic Windows Event logging function
    function Add-Log ([string] $EntryType, [string] $Message) {
        $Param = @{
            LogName   = 'PSFalcon'
            Source    = 'PSFalcon'
            EventId   = 2793
            EntryType = $EntryType
            Message   = $Message
        }
        Write-EventLog @Param

        # If error was logged, output error and end script
        if ($EntryType -eq 'Error') {
            Write-Error $Message
            break
        }
    }
    # Create $PSScriptRoot (PSv2 compatible)
    if (-not($PSScriptRoot)) {
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    }
    # Calculate SHA256 hash value (PSv2 compatible)
    function Get-SHA256 ([string] $Path) {
        $Algorithm = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
        $Value = [System.BitConverter]::ToString($Algorithm.ComputeHash([System.IO.File]::ReadAllBytes($Path)))
        return ($Value.Replace('-', ''))
    }
    # Convert Json from API into an array (PSv2 compatible)
    function Convert-Result ([object] $Json, [string] $Uri) {
        $Serializer = New-Object System.Web.Script.Serialization.JavascriptSerializer
        $Result = ,$Serializer.DeserializeObject($Json)

        # Log result
        if ($Result.errors) {
            $EntryType = 'Error'
            $Message   = "$($Result.errors.code): $($Result.errors.message)`n$($Result.meta.trace_id) $Uri"
        } else {
            $EntryType = 'Information'
            $Message   = "$($Result.meta.trace_id) $Uri"
        }
        Add-Log -EntryType $EntryType -Message $Message

        # Output result
        return $Result
    }
    # CrowdStrike Falcon API request and conversion (PSv2 compatible)
    function Invoke-Falcon ($Uri, $Method, $Body, $Outfile) {
        if ($OutFile) {
            # Download request for installer package
            $Download = New-Object System.Net.WebClient
            $Download.Headers.Add('Authorization', $Authorization)
            $Download.DownloadFile(($ApiHost + $Uri), $Outfile)
        } else {
            # Create .NET WebRequest
            $WebRequest = [System.Net.WebRequest]::Create(($ApiHost + $Uri))
            $WebRequest.Method = $Method
            $WebRequest.Accept = 'application/json'
            $WebRequest.UserAgent = "InstallFalcon Powershell Script/1.5"

            if ($Method -eq 'get') {
                try {
                    # Add authorization, make request
                    $WebRequest.ContentType = 'application/json'
                    $WebRequest.Headers.Add('Authorization', $Authorization)
                    $RequestStream = ($WebRequest.GetResponse()).GetResponseStream()
                    $StreamReader = New-Object System.IO.StreamReader $RequestStream

                    # Convert result to Json and log
                    Convert-Result -Json $StreamReader.ReadToEnd() -Uri $Uri
                } finally {
                    # Close open streams
                    if ($null -ne $StreamReader) { $StreamReader.Dispose() }
                    if ($null -ne $RequestStream) { $RequestStream.Dispose() }
                }
            } elseif ($Method -eq 'post') {
                try {
                    # Make OAuth2 token request
                    $WebRequest.ContentType = 'application/x-www-form-urlencoded'
                    $RequestStream = $WebRequest.GetRequestStream()
                    $StreamWriter = New-Object System.IO.StreamWriter $RequestStream
                    $StreamWriter.Write($Body)
                    $StreamWriter.Flush()
                    $StreamWriter.Close()
                    $Response = $WebRequest.GetResponse()
                    $ResponseStream = $Response.GetResponseStream()
                    $StreamReader = [System.IO.StreamReader]($ResponseStream)

                    # Convert result to Json and log
                    Convert-Result -Json $StreamReader.ReadToEnd() -Uri $Uri
                } finally {
                    # Close open streams
                    if ($null -ne $StreamWriter) { $StreamWriter.Dispose() }
                    if ($null -ne $RequestStream) { $RequestStream.Dispose() }
                }
            }
        }
    }
    # Load assemblies for .NET interaction
    Add-Type -AssemblyName System.Web
    Add-Type -AssemblyName System.Web.Extensions
}
process {
    if (-not(Get-Service | Where-Object { $_.Name -eq 'CSFalconService' })) {
        # Request OAuth2 token
        $Param = @{
            Uri = '/oauth2/token'
            Method = 'post'
            Body = "client_id=$ApiClient&client_secret=$ApiSecret"
        }
        if ($MemberCID) {
            $Param.Body += "&member_cid=$MemberCID"
        }
        $Token = Invoke-Falcon @Param

        if ($Token.token_type -and $Token.access_token) {
            $Authorization = "$($Token.token_type) $($Token.access_token)"

            if ($PolicyName) {
                # Retrieve details for $PolicyName
                $Param = @{
                    Uri = '/policy/combined/sensor-update/v2?filter=' + [System.Web.HTTPUtility]::UrlEncode(
                        "platform_name:'Windows'+name:'$($PolicyName.ToLower())'")
                    Method = 'get'
                }
                $Policy = Invoke-Falcon @Param

                # Capture $MinorVersion from $PolicyName
                $MinorVersion = ($BuildRegex.Matches($Policy.resources.settings.build)).value
            }
            # Retrieve list of installer files
            $InstallerList = if ($Version) {
                $Param = @{
                    Uri = '/sensors/combined/installers/v1?filter=' +
                        [System.Web.HTTPUtility]::UrlEncode("platform:'windows'+version:'$Version'")
                    Method = 'get'
                }
                Invoke-Falcon @Param
            } else {
                $Param = @{
                    Uri = "/sensors/combined/installers/v1?filter=platform:'windows'"
                    Method = 'get'
                }
                Invoke-Falcon @Param
            }
            # Retrieve CCID
            $Param = @{
                Uri = '/sensors/queries/installers/ccid/v1'
                Method = 'get'
            }
            $CCID = (Invoke-Falcon @Param).resources

            # Capture SHA256 and name of target installer file
            $CloudHash = if ($MinorVersion) {
                ($InstallerList.resources | Where-Object { $_.version -match $MinorVersion }).sha256
            } else {
                $InstallerList.resources[0].sha256
            }
            $InstallerName = if ($MinorVersion) {
                ($InstallerList.resources | Where-Object { $_.version -match $MinorVersion }).name
            } else {
                $InstallerList.resources[0].name
            }
            # Set path for installer file
            [string] $InstallerPath = "$PSScriptRoot\$InstallerName"

            # Download installer file
            $Param = @{
                Uri = "/sensors/entities/download-installer/v1?id=$CloudHash"
                Method = 'get'
                Outfile = $InstallerPath
            }
            Invoke-Falcon @Param

            if (Test-Path $InstallerPath) {
                # Compare local hash against cloud hash
                $LocalHash = Get-SHA256 -Path $InstallerPath

                if ($CloudHash -eq $LocalHash) {
                    # Start installer
                    $InstallerPID = (Start-Process -FilePath $InstallerPath -ArgumentList $InstallArguments -PassThru).id

                    if (Get-Process | Where-Object { $_.Id -eq $InstallerPID }) {
                        Add-Log -EntryType 'Information' -Message (
                            "$($MyInvocation.MyCommand.Name) started $InstallerPath")
                    }
                    if ($DeleteInstaller -eq $true) {
                        # Wait for process to finish, then delete installer file
                        Wait-Process $InstallerPID

                        Add-Log -EntryType 'Information' -Message "$InstallerPath ended"

                        Remove-Item -Path $InstallerPath -Force

                        if ((Test-Path $InstallerPath) -eq $false) {
                            Add-Log -EntryType 'Information' -Message (
                                "$($MyInvocation.MyCommand.Name) deleted $InstallerPath")
                        } else {
                            Add-Log -EntryType 'Warning' -Message (
                                "$($MyInvocation.MyCommand.Name) failed to delete $InstallerPath")
                        }
                    }
                    if ($DeleteScript -eq $true) {
                        # Set script path
                        [string] $ScriptPath = "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"

                        # Delete script
                        Remove-Item -Path $ScriptPath -Force

                        if ((Test-Path $ScriptPath) -eq $false) {
                            Add-Log -EntryType 'Information' -Message (
                                "$($MyInvocation.MyCommand.Name) deleted $ScriptPath")
                        } else {
                            Add-Log -EntryType 'Warning' -Message (
                                "$($MyInvocation.MyCommand.Name) failed to delete $ScriptPath")
                        }
                    }
                } else {
                    # Output error for failed hash check
                    Add-Log -EntryType 'Error' -Message ("$($MyInvocation.MyCommand.Name) failed hash check on " +
                        "$InstallerPath [cloud: $CloudHash, local: $LocalHash]")
                }
            }
        }
    } else {
        if ($DeleteScript -eq $true) {
            # Delete script
            Remove-Item -Path $ScriptPath -Force

            if ((Test-Path $ScriptPath) -eq $false) {
                Add-Log -EntryType 'Information' -Message (
                    "$($MyInvocation.MyCommand.Name) deleted $ScriptPath")
            } else {
                Add-Log -EntryType 'Warning' -Message (
                    "$($MyInvocation.MyCommand.Name) failed to delete $ScriptPath")
            }
        }
        Add-Log -EntryType 'Error' -Message ("Aborted: CSFalconService already running")
    }
}