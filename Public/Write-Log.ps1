function Write-Log {
    param(
        [Parameter(Mandatory = $true)]        
        [object]$LogEntry # Changed parameter to accept an object (e.g., Hashtable or PSObject)
    )
    #$logFile = "D:\testMCP\mcp_server.log"
    # Add a timestamp to the log entry
    $logObject = $LogEntry | Select-Object *, @{Name = 'Timestamp'; Expression = { (Get-Date -Format 'o') } }
    # Convert the object to a JSON string and append to the log file
    $logObject | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $script:logFile
}
