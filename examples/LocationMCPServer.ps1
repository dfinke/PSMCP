#Requires -Module PSMCP

Set-LogFile "$PSScriptRoot\mcp_server.log"

<#
.SYNOPSIS 
   Get my public IP Address  

   .DESCRIPTION
   Uses http://ipinfo.io/json to get the public IP Address of the machine running this script.
   This is useful for testing and debugging purposes, especially when working with APIs that require a public IP Address.

   .EXAMPLE
    Get-PublicIPAddress

    .OUTPUTS
    Returns the public IP Address of the machine running the script.
#>

function Global:Get-PublicIPAddress {
    [CmdletBinding()]
    Param
    ()
    Begin {
        Write-Verbose -Message "Getting public IP Address"
    }
    Process {
        try {
            $ip = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
            Write-Output $ip
        }
        catch {
            Write-Warning -Message "Unable to get public IP Address: $_"
        }
    }
    End {
    }
}


<#
.Synopsis
   Can resolve either an IP Address or a Domain Name and give you geolocation information.
.DESCRIPTION
   This module is using https://freegeoip.live API which is free. Yes. It's totally free. They believe that digital businesses need to get such kind of service for free. Many services are selling Geoip API as a service, but they think that it should be totally free. Feel free to their API as much as you want without any limit other than 10,000 queries per hour for one IP address. I thought this would be another good addition to add to the Powershell Gallery.
.Parameter IP
   This parameter is used to specify the IP Address you want to find the geolocation information
.Parameter DomainName
   This parameter is used to specify the Domain Name address you want to find the geolocation information
.EXAMPLE
   Find-Geolocation -DomainName portsmouth.co.uk
.EXAMPLE
   Find-Geolocation -IP 141.193.213.10
#>
function Global:Find-Geolocation {
    [CmdletBinding()]
    Param
    (
        [Parameter(ParameterSetName = 'IP Address Parameter Set')]
        [ipaddress]$IP,
        [Parameter(ParameterSetName = 'Domain Name Parameter Set')]
        [System.Uri]$DomainName
    )

    Begin {
        if ($IP) {
            $Pattern = $IP
        }
        if ($DomainName) {
            $Pattern = $DomainName
        }
    }
    Process {
        foreach ($item in $Pattern) {
            Write-Verbose -Message "About to find out more information on $item"
            try {
                Invoke-RestMethod -Method Get -Uri https://freegeoip.live/json/$item -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "$item : $_"
            }
        }
    }
    End {
    }
}

Start-McpServer Find-Geolocation, Get-PublicIPAddress
