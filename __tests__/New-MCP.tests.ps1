Describe 'New-MCP' -Tag New-MCP -Skip {
    BeforeAll {
        Import-Module $PSScriptRoot\..\PSMCP.psd1 -Force
    }

    AfterAll {
        Remove-Item -Recurse -Force TestDrive:\
    }
    
    It "Should create the stuff on the testdrive" {
        $testDrive = "TestDrive:"
        $testPath = "$testDrive\DougFolder"
        mkdir $testPath -Force | Out-Null

        $actual = New-MCP -Path $testPath -Force

        Test-Path "$testPath\.vscode" | Should -Be $true 
        Test-Path "$testPath\.vscode\mcp.json" | Should -Be $true
        Test-Path "$testPath\MCPServer.ps1" | Should -Be $true 
        
        #Get-Content "$testPath\.vscode\mcp.json" | Out-Host
        $expectedResults = @'
{
    "servers": {
        "mcp-powershell-MCPServer": {
            "type": "stdio",
            "command": "pwsh",
            "args": [
                "-NoProfile",
                "-Command",
                "${workspaceFolder}\\MCPServer.ps1"
            ]
        }
    }
}
'@
        $actual = Get-Content "$testPath\.vscode\mcp.json" -Raw

        ($actual | ConvertFrom-Json -Depth 10 | ConvertTo-Json -Depth 10 -Compress) | Should -Be ($expectedResults | ConvertFrom-Json -Depth 10 | ConvertTo-Json -Depth 10 -Compress )

        $serverFileContent = @'
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

Start-McpServer Invoke-Addition
'@

        $expectedLines = $serverFileContent -split "`r?`n"
        $fileLines = Get-Content "$testPath\MCPServer.ps1" 

        $fileLines.Count | Should -Be $expectedLines.Count

        for ($i = 0; $i -lt $expectedLines.Count; $i++) {
            $fileLines[$i].Trim() | Should -Be $expectedLines[$i].Trim()
        }
    }

    It "Should have these params and in order" {
        $expectedParams = 'Path', 'ServerName', 'template', 'Force'

        $actualParams = (Get-Command New-MCP).Parameters.Keys

        $actualParams.Count | Should -Be $expectedParams.Count

        for ($i = 0; $i -lt $expectedParams.Count; $i++) {
            $actualParams[$i] | Should -Be $expectedParams[$i]
        }
    }
}