function Invoke-HandleRequest {
    param(
        [object]$request,
        [string]$toolsListJson
    )

    # Initialize Method
    if ($request.method -eq "initialize") {
        # Static response for simplicity, adjust serverInfo as needed
        $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"protocolVersion":"0.3.0","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"PowerShell MCP Server (Template)","version":"0.1.0"}}}'
        return $response
    }

    # Ping Method
    if ($request.method -eq "ping") {
        $pingResponse = @{
            jsonrpc = "2.0"
            id      = $request.id
            result  = @{}
        }

        $response = $pingResponse | ConvertTo-Json -Depth 10 -Compress
        return $response
    }

    # Tools/List Method
    if ($request.method -eq "tools/list") {

        $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"tools":' + $toolsListJson + '}}'

        # Use the Write-Log function correctly with a hashtable
        Write-Log -LogEntry @{
            RequestId   = $request.id
            Method      = $request.method
            FullRequest = ($request | ConvertTo-Json -Depth 10 -Compress) # Keep as string if preferred, or parse if needed elsewhere
            ToolsList   = $toolsListJson # Keep as string
        }

        return $response
    }

    # Tools/Call Method
    if ($request.method -eq "tools/call") {
        $toolName = $request.params.name
        $targetArgs = $request.params.arguments | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10 -AsHashtable

        # Derive the set of allowed tool names from the configured tools list JSON.
        $allowedToolNames = @()
        try {
            $parsedTools = $toolsListJson | ConvertFrom-Json -Depth 10

            if ($parsedTools -is [System.Array]) {
                # Expecting an array of tool objects with a 'name' property.
                $allowedToolNames = $parsedTools | ForEach-Object { $_.name } | Where-Object { $_ }
            }
            elseif ($parsedTools -ne $null) {
                # Handle object shapes like @{ tools = @(@{ name = "..." }, ...) } or a single tool object.
                if ($parsedTools.PSObject.Properties.Name -contains 'tools' -and $parsedTools.tools) {
                    $allowedToolNames = $parsedTools.tools | ForEach-Object { $_.name } | Where-Object { $_ }
                }
                elseif ($parsedTools.PSObject.Properties.Name -contains 'name') {
                    $allowedToolNames = @($parsedTools.name) | Where-Object { $_ }
                }
            }
        }
        catch {
            # If parsing fails, leave $allowedToolNames empty to avoid executing arbitrary tools.
            $allowedToolNames = @()
        }

        # Validate that the requested tool name is in the allowed list.
        if (-not ($allowedToolNames -and ($allowedToolNames -contains $toolName))) {
            $errorResponse = [ordered]@{
                jsonrpc = "2.0"
                id      = $request.id
                error   = @{
                    code    = -32602
                    message = "Invalid or unauthorized tool name: '$toolName'."
                }
            }

            return ($errorResponse | ConvertTo-Json -Depth 10 -Compress)
        }
        $result = & $toolName @targetArgs

        $resultText = if ($null -eq $result) {
            ""
        }
        elseif ($result -is [string]) {
            $result
        }
        elseif ($result -is [ValueType]) {
            $result.ToString()
        }
        else {
            try {
                $result | ConvertTo-Json -Depth 100
            }
            catch {
                # Fallback to a safer string representation if JSON serialization fails
                try {
                    $result | Out-String
                }
                catch {
                    $result.ToString()
                }
            }
        }

        # Log structured data
        Write-Log -LogEntry @{
            RequestId = $request.id
            Method    = $request.method
            ToolName  = $toolName
            Arguments = $targetArgs
            Result    = $result
            # FullRequest = $request # Optionally include the full request if needed, can be large
        }

        $response = [ordered]@{
            jsonrpc = "2.0"
            id      = $request.id
            result  = @{
                content = @(
                    [ordered]@{
                        type = "text"
                        text = $resultText
                    }
                )
                isError = $false
            }
        }

        return ($response | ConvertTo-Json -Depth 10 -Compress)
    }

    # Unknown Method Error
    $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"error":{"code":-32601,"message":"Method not found"}}'

    return $response
}
