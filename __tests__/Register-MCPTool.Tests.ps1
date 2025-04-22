Describe "Register-MCPTool" {
    BeforeAll {
        Import-Module $PSScriptRoot\..\PSMCP.psd1 -Force

        Set-LogFile TestDrive:\mcp_server.log
        
        . $PSScriptRoot/sampleFunctions/Invoke-Greet.ps1
        . $PSScriptRoot/sampleFunctions/Invoke-Addition.ps1
    }
    AfterAll {
        Remove-Item -Recurse -Force TestDrive:\
    }

    It "Should return JSON for Invoke-Greet in an MCP server " {
        $expectedOutput = @"
{"name":"Invoke-Greet","description":"Invoke-Greet","inputSchema":{"type":"object","properties":{"Name":{"type":"string","description":"The name of the user to greet."}},"required":["Name"]},"returns":{"type":"string","description":"Invoke-Greet"}}
"@  
        $actualOutput = Register-MCPTool -FunctionName Invoke-Greet

        # Assert that the output is as expected
        $actualOutput | Should -Be $expectedOutput
    }    

    It "Should return JSON for Invoke-Addition in an MCP server " {
        $expectedOutput = @"
{"name":"Invoke-Addition","description":"Invoke-Addition","inputSchema":{"type":"object","properties":{"Number1":{"type":"number","description":"The first number to add."},"Number2":{"type":"number","description":"The second number to add."}},"required":["Number1","Number2"]},"returns":{"type":"string","description":"Invoke-Addition"}}
"@

        $actualOutput = Register-MCPTool -FunctionName Invoke-Addition
        $actualOutput | Should -Be $expectedOutput    
    }

    It "Should return JSON for Invoke-Greet and Invoke-Addition in an MCP server " {
        $expectedOutput = @"
[{"name":"Invoke-Greet","description":"Invoke-Greet","inputSchema":{"type":"object","properties":{"Name":{"type":"string","description":"The name of the user to greet."}},"required":["Name"]},"returns":{"type":"string","description":"Invoke-Greet"}},{"name":"Invoke-Addition","description":"Invoke-Addition","inputSchema":{"type":"object","properties":{"Number1":{"type":"number","description":"The first number to add."},"Number2":{"type":"number","description":"The second number to add."}},"required":["Number1","Number2"]},"returns":{"type":"string","description":"Invoke-Addition"}}]
"@

        $actualOutput = Register-MCPTool -FunctionName Invoke-Greet, Invoke-Addition
        $actualOutput | Should -Be $expectedOutput    
    }
}