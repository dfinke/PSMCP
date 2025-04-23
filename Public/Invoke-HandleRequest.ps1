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

        $result = & $toolName @targetArgs

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
                        text = $result | Out-String
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
