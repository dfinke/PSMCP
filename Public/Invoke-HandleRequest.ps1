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

        try {
            # Redirect all streams (Error=2, Warning=3, Verbose=4, Debug=5, Information=6) to the
            # output stream so they arrive in chronological order and can be logged by type
            $rawOutput = & $toolName @targetArgs 2>&1 3>&1 4>&1 5>&1 6>&1

            # Walk output in order — log stream records, collect actual output
            $actualOutput = [System.Collections.Generic.List[object]]::new()
            $hadErrors = $false

            foreach ($item in $rawOutput) {
                $level = $null
                $stream = $null
                $extra = @{}

                switch ($item) {
                    { $_.GetType().FullName -notmatch '^System\.Management\.Automation\.(Error|Warning|Verbose|Debug|Information)Record$' } {
                        $actualOutput.Add($item); break
                    }
                    { $_ -is [System.Management.Automation.ErrorRecord] } {
                        $hadErrors = $true
                        $level = 'Error'
                        $stream = 'Error'
                        $extra = @{ Category = $item.CategoryInfo.ToString() }
                        break
                    }
                    { $_ -is [System.Management.Automation.WarningRecord] } { $level = 'Warn'; $stream = 'Warning'; break }
                    { $_ -is [System.Management.Automation.VerboseRecord] } { $level = 'Verbose'; $stream = 'Verbose'; break }
                    { $_ -is [System.Management.Automation.DebugRecord] } { $level = 'Debug'; $stream = 'Debug'; break }
                    { $_ -is [System.Management.Automation.InformationRecord] } {
                        $level = 'Info'
                        $stream = 'Information'
                        $extra = @{ Tags = ($item.Tags -join ',') }
                        break
                    }
                }

                if ($level) {
                    Write-Log -LogEntry (@{
                            Level    = $level
                            Message  = $item.ToString()
                            ToolName = $toolName
                            Stream   = $stream
                        } + $extra)
                }
            }

            Write-Log -LogEntry @{
                Level     = 'Info'
                RequestId = $request.id
                Method    = $request.method
                ToolName  = $toolName
                Arguments = $targetArgs
                Result    = ($actualOutput | Out-String)
            }

            $response = [ordered]@{
                jsonrpc = "2.0"
                id      = $request.id
                result  = @{
                    content = @(
                        [ordered]@{
                            type = "text"
                            text = if ($hadErrors) {
                                ($rawOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"
                            }
                            else {
                                $actualOutput | Out-String
                            }
                        }
                    )
                    isError = $hadErrors
                }
            }

            return ($response | ConvertTo-Json -Depth 10 -Compress)
        }
        catch {
            Write-Log -LogEntry @{
                Level     = 'Error'
                Message   = $_.Exception.Message
                ToolName  = $toolName
                Stream    = 'Exception'
                Exception = $_.ToString()
            }

            $response = [ordered]@{
                jsonrpc = "2.0"
                id      = $request.id
                result  = @{
                    content = @(
                        [ordered]@{
                            type = "text"
                            text = $_.Exception.Message
                        }
                    )
                    isError = $true
                }
            }

            return ($response | ConvertTo-Json -Depth 10 -Compress)
        }
    }

    # Unknown Method Error
    $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"error":{"code":-32601,"message":"Method not found"}}'

    return $response
}
