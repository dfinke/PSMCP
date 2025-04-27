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

Start-McpServer Invoke-Addition