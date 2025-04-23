function Start-McpServer {
    param(
        [string]$toolsListJson
    )

    while ($true) {
        $inputLine = [Console]::In.ReadLine()
        if ([string]::IsNullOrEmpty($inputLine)) { continue }
        try {
            $request = $inputLine | ConvertFrom-Json -ErrorAction Stop
            if ($request.id) {
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
