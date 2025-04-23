#Requires -Module PSMCP

Set-LogFile "$PSScriptRoot\mcp_server.log"

<#
.SYNOPSIS
    Adds two numbers together.

.DESCRIPTION
    The Invoke-Addition function takes two numeric parameters and returns their sum.

.PARAMETER a
    The first number to add.

.PARAMETER b
    The second number to add.
#>
function Global:Invoke-Addition {
    param(
        [Parameter(Mandatory)]
        [double]$a, 
        [Parameter(Mandatory)]
        [double]$b
    ) 

    $a + $b
}

$toolsListJson = Register-MCPTool Invoke-Addition


Start-McpServer $toolsListJson