function Start-McpServer {
    param(
        [string[]]$Tools
    )

    # Get parent process ID to monitor for disconnection
    $currentProcess = Get-Process -Id $PID
    $parentProcessId = $currentProcess.Parent.Id
    Write-Log -LogEntry @{ Level = 'Info'; Message = "MCP Server started with PID: $PID, Parent PID: $parentProcessId" }

    # Check if the tools are provided
    if (-not $Tools) {
        Write-Log -LogEntry @{ Level = 'Error'; Message = "No tools provided to Start-McpServer" }
        return
    }
    # Convert the tools list to JSON format
    $toolsListJson = Register-MCPTool $Tools

    Write-Log -LogEntry @{ Level = 'Info'; Message = "Starting MCP Server" }
    while ($true) {

        # Check if parent process is still running otherwise exit
        try {
            $parentProcess = Get-Process -Id $parentProcessId -ErrorAction Stop
            if ($null -eq $parentProcess) {
                Write-Log -LogEntry @{ Level = 'Info'; Message = "Parent process has exited. Shutting down MCP server..." }
                exit
            }
        }
        catch {
            Write-Log -LogEntry @{ Level = 'Info'; Message = "Parent process not found. Shutting down MCP server..." }
            exit
        }
    
        $inputLine = [Console]::In.ReadLine()
        if ([string]::IsNullOrEmpty($inputLine)) { continue }
        try {
            $request = $inputLine | ConvertFrom-Json -ErrorAction Stop
            if ($request.id) {
                # Handle the request and get the response
                Write-Log -LogEntry @{ Level = 'Info'; Message = "Processing request"; RequestId = $request.id; Request = $inputLine }
                $jsonResponse = Invoke-HandleRequest -request $request -toolsListJson $toolsListJson
                [Console]::WriteLine($jsonResponse)
                [Console]::Out.Flush()
            }
        }
        catch {
            # ignore parsing or handler errors
        }
    }
}
