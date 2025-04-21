# PowerShell MCP Server Template

# Source the functions defined in the main script (if any)
$SourceFilePath = "##SOURCE_FILE##" # Placeholder will be replaced
if (Split-Path -Path $SourceFilePath -IsAbsolute) {
    . $SourceFilePath
}
else {
    . (Join-Path -Path $PSScriptRoot -ChildPath $SourceFilePath)
}

# Register the specified tools using Register-Tool from the PSMCP module
# Assumes PSMCP module is loaded and Register-Tool populates $RegisteredMCPTools
$toolsJson = $($toolRegistrations)

# --- MCP Request Handling Logic ---

function Invoke-HandleRequest {
    param([object]$request)

    # Initialize Method
    if ($request.method -eq "initialize") {
        # Static response for simplicity, adjust serverInfo as needed
        $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"protocolVersion":"0.3.0","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"PowerShell MCP Server (Template)","version":"0.1.0"}}}'
        return $response
    }

    # Ping Method
    if ($request.method -eq "ping") {
        $requestId = ($request.id | ConvertTo-Json -Depth 10 -Compress)
        $response = @"
{
    "jsonrpc":"2.0",
    "id":"$($requestId)",
    "result":{}
}
"@
        return $response
    }

    # Tools/List Method
    if ($request.method -eq "tools/list") {
        # Assumes Register-Tool populates a global variable like $RegisteredMCPTools
        # Or provides a function like Get-RegisteredToolSpec
        if ($null -eq $RegisteredMCPTools -or $RegisteredMCPTools.Count -eq 0) {
            $toolsListJson = '[]'
        }
        else {
            $toolsList = @()
            foreach ($toolName in $RegisteredMCPTools.Keys) {
                $toolSpec = $RegisteredMCPTools[$toolName] # Assuming this contains name, description, parameters
                # Construct the MCP tool spec format
                $mcpToolSpec = @{
                    name        = $toolSpec.name
                    description = $toolSpec.description
                    parameters  = $toolSpec.parameters # Assuming parameters are already in OpenAPI format
                }
                $toolsList += $mcpToolSpec | ConvertTo-Json -Depth 10 -Compress
            }
            $toolsListJson = '[' + ($toolsList -join ",") + ']'
        }
        $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"tools":' + $toolsListJson + '}}'
        return $response
    }

    # Tools/Call Method
    if ($request.method -eq "tools/call") {
        $toolName = $request.params.name
        $targetArgs = $request.params.arguments | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10 -AsHashtable

        # Find the tool and its execution logic (ScriptBlock or Function Name)
        $toolInfo = $RegisteredMCPTools[$toolName]

        if ($null -ne $toolInfo) {
            try {
                # Assuming the tool registration stores a ScriptBlock or FunctionName
                if ($toolInfo.scriptBlock) {
                    $result = & $toolInfo.scriptBlock @targetArgs
                }
                elseif ($toolInfo.functionName) {
                    $result = & $toolInfo.functionName @targetArgs
                }
                else {
                    throw "Tool '$toolName' is registered but has no execution logic (ScriptBlock or FunctionName)."
                }

                $response = @{
                    jsonrpc = "2.0"
                    id      = $request.id
                    result  = @{
                        content = @(
                            @{
                                type = "text"
                                text = $result | Out-String
                            }
                        )
                        isError = $false
                    }
                }
            }
            catch {
                # Handle errors during tool execution
                $errorMessage = $_.Exception.Message
                $response = @{
                    jsonrpc = "2.0"
                    id      = $request.id
                    result  = @{
                        content = @(
                            @{
                                type = "text"
                                text = "Error executing tool '$toolName': $errorMessage"
                            }
                        )
                        isError = $true
                    }
                }
            }
        }
        else {
            # Tool not found error
            $response = @{
                jsonrpc = "2.0"
                id      = $request.id
                error   = @{
                    code    = -32601 # Method not found
                    message = "Tool not found: $toolName"
                }
            }
        }
        return ($response | ConvertTo-Json -Depth 10 -Compress)
    }

    # Unknown Method Error
    $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"error":{"code":-32601,"message":"Method not found"}}'
    return $response
}

# --- Main Server Loop ---
while ($true) {
    $inputLine = [Console]::In.ReadLine()
    if ([string]::IsNullOrEmpty($inputLine)) { continue }

    try {
        $request = $inputLine | ConvertFrom-Json -ErrorAction Stop
        # Handle only requests with an ID (ignore notifications for now)
        if ($request.id) {
            $jsonResponse = Invoke-HandleRequest -request $request
            [Console]::WriteLine($jsonResponse)
            [Console]::Out.Flush()
        }
    }
    catch {
        # Handle JSON parsing errors or other issues reading input
        # Log error appropriately, maybe return a JSON-RPC error response if possible
        Write-Error "Failed to parse request or handle input line: $($_.Exception.Message)"
        # Consider sending a generic error response if a request ID can be parsed or assumed
        # $errorResponse = '{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}'
        # [Console]::WriteLine($errorResponse)
        # [Console]::Out.Flush()
    }
}
