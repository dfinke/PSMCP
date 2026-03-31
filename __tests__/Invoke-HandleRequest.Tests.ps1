Describe 'Invoke-HandleRequest tools/call with PowerShell.Create' {
    BeforeAll {
        Import-Module $PSScriptRoot\..\PSMCP.psd1 -Force
        Set-LogFile TestDrive:\mcp_server.log
        . $PSScriptRoot/sampleFunctions/Invoke-StreamTest.ps1
        $toolsListJson = Register-MCPTool -FunctionName Invoke-StreamTest
    }

    AfterAll {
        Remove-Item -Recurse -Force TestDrive:\ -ErrorAction SilentlyContinue
    }

    It 'Should capture normal output as text content' {
        $request = @{
            jsonrpc = '2.0'
            id      = 1
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'normal' } }
        }
        $response = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson | ConvertFrom-Json
        $response.result.content[0].text.Trim() | Should -Be 'Normal output'
        $response.result.isError | Should -BeFalse
    }

    It 'Should set isError true when tool writes to error stream' {
        $request = @{
            jsonrpc = '2.0'
            id      = 2
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'error' } }
        }
        $response = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson | ConvertFrom-Json
        $response.result.isError | Should -BeTrue
    }

    It 'Should include error message in text when tool writes to error stream' {
        $request = @{
            jsonrpc = '2.0'
            id      = 3
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'error' } }
        }
        $response = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson | ConvertFrom-Json
        $response.result.content[0].text | Should -BeLike '*Test error message*'
    }

    It 'Should set isError true when tool throws a terminating error' {
        $request = @{
            jsonrpc = '2.0'
            id      = 4
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'throw' } }
        }
        $response = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson | ConvertFrom-Json
        $response.result.isError | Should -BeTrue
        $response.result.content[0].text | Should -BeLike '*Test terminating error*'
    }

    It 'Should log warning stream records with Level Warn' {
        $logFile = 'TestDrive:\mcp_server.log'
        Set-Content -Path $logFile -Value ''
        $request = @{
            jsonrpc = '2.0'
            id      = 5
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'warning' } }
        }
        $null = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson
        $logContent = Get-Content $logFile | Where-Object { $_ } | ForEach-Object { ConvertFrom-Json -InputObject:$_ }
        $warnEntry = $logContent | Where-Object { $_.Level -eq 'Warn' -and $_.Stream -eq 'Warning' }
        $warnEntry | Should -Not -BeNullOrEmpty
        $warnEntry.Message | Should -BeLike '*Test warning message*'
    }

    It 'Should still return output when tool also writes warnings' {
        $request = @{
            jsonrpc = '2.0'
            id      = 6
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'warning' } }
        }
        $response = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson | ConvertFrom-Json
        $response.result.content[0].text.Trim() | Should -Be 'output after warning'
        $response.result.isError | Should -BeFalse
    }

    It 'Should log error stream records with Level Error' {
        $logFile = 'TestDrive:\mcp_server.log'
        Set-Content -Path $logFile -Value ''
        $request = @{
            jsonrpc = '2.0'
            id      = 7
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'error' } }
        }
        $null = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson
        $logContent = Get-Content $logFile | Where-Object { $_ } | ForEach-Object { ConvertFrom-Json -InputObject:$_ }
        $errorEntry = $logContent | Where-Object { $_.Level -eq 'Error' -and $_.Stream -eq 'Error' }
        $errorEntry | Should -Not -BeNullOrEmpty
        $errorEntry.Message | Should -BeLike '*Test error message*'
    }

    It 'Should log terminating errors with Level Error and Stream Exception' {
        $logFile = 'TestDrive:\mcp_server.log'
        Set-Content -Path $logFile -Value ''
        $request = @{
            jsonrpc = '2.0'
            id      = 8
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'throw' } }
        }
        $null = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson
        $logContent = Get-Content $logFile | ConvertFrom-Json
        $exceptionEntry = $logContent | Where-Object { $_.Level -eq 'Error' -and $_.Stream -eq 'Exception' }
        $exceptionEntry | Should -Not -BeNullOrEmpty
        $exceptionEntry.Message | Should -BeLike '*Test terminating error*'
    }

    It 'Should log verbose stream records with Level Verbose' {
        $logFile = 'TestDrive:\mcp_server.log'
        Set-Content -Path $logFile -Value ''
        $request = @{
            jsonrpc = '2.0'
            id      = 9
            method  = 'tools/call'
            params  = @{ name = 'Invoke-StreamTest'; arguments = @{ Action = 'verbose'; Verbose = $true } }
        }
        $null = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson
        $logContent = Get-Content $logFile | Where-Object { $_ } | ForEach-Object { ConvertFrom-Json -InputObject:$_ }
        $verboseEntry = $logContent | Where-Object { $_.Level -eq 'Verbose' -and $_.Stream -eq 'Verbose' }
        $verboseEntry | Should -Not -BeNullOrEmpty
        $verboseEntry.Message | Should -BeLike '*Test verbose message*'
    }
}
