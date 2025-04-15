# Role and Objective
you are an expert powershell developer. 

# Instructions
Add an MCP switch to the Public/Register-Tool.ps1 function. Create `Public/Get-MCPFunctionCallSpec.ps1` mirroring `Public/Get-OAIFunctionCallSpec.ps1`

It takes as input a PowerShell. Using `Get-Command` if figures out the function name and the parameters. It then creates a JSON object that describes the function, its parameters, and their types. The JSON object should be structured in a way that is compatible with the anthropic MCP Tool definition.

```powershell
function script:reverse {
    <#
        .SYNOPSIS 
        Reverse the input text.
        .DESCRIPTION
        Reverse the input text.
        .PARAMETER text
        The text to reverse.
    #>
    param([string]$text)

    $charArray = $text.ToCharArray()
    [array]::Reverse($charArray)
    return -join $charArray
}
```

It needs to output this json:
```json
{"reverse":{"returns":{"type":"string","description":"The reversed text"},"description":"Reverse the input text","inputSchema":{"properties":{"text":{"type":"string","description":"Text to reverse"}},"required":["text"],"type":"object"},"name":"reverse"}}
```

# Final instructions and prompt to think step by step
`Public/Get-OAIFunctionCallSpec.ps1` does this process reads the function signature and comment based help. It generates a hashtable based on the function calling spec for OpenAI.

`Public/Get-MCPFunctionCallSpec.ps1` should do the same but for the MCP tool. The MCP tool is a new tool that anthropic has released. It is similar to OpenAI's function calling spec but has some differences. The main difference is that it uses a different JSON schema for the input and output. 

`Public/Get-MCPFunctionCallSpec.ps1` will return a JSON string