

Import-Module $PSScriptRoot\PSMCP.psd1 -Force

function Invoke-Greet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    Write-Output "Hello, $Name!"
}

Register-MCPTool Invoke-Greet