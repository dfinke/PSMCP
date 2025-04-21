# Simple PowerShell MCP Server Implementation (JSON string responses only)

$toolsJson = . $PSScriptRoot\testPS-For-MCP.ps1

function Invoke-HandleRequest {
  param([object]$request)

  if ($request.method -eq "initialize") {

    $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"protocolVersion":"0.3.0","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"Simple PowerShell MCP Server","version":"0.1.0"}}}'

    return $response
  }

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

  if ($request.method -eq "tools/list") {
    $toolsObj = $toolsJson | ConvertFrom-Json -Depth 10
    $toolsList = @()
    foreach ($toolKey in $toolsObj.PSObject.Properties.Name) {
      $toolsList += $toolsObj.$toolKey | ConvertTo-Json -Depth 10 -Compress
    }
    $toolsListJson = '[' + ($toolsList -join ",") + ']'
    $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"result":{"tools":' + $toolsListJson + '}}'
    return $response
  }

  if ($request.method -eq "tools/call") {
    $toolName = $request.params.name
    $targetArgs = $request.params.arguments | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10 -AsHashtable
    $result = & $toolName @targetArgs
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
    return ($response | ConvertTo-Json -Depth 10 -Compress)
  }

  # Unknown method
  $response = '{"jsonrpc":"2.0","id":' + ($request.id | ConvertTo-Json -Depth 10 -Compress) + ',"error":{"code":-32601,"message":"Method not found"}}'
  return $response
}

while ($true) {
  $inputLine = [Console]::In.ReadLine()
  if ([string]::IsNullOrEmpty($inputLine)) { continue }
  $request = $inputLine | ConvertFrom-Json
  if (-not $request.id -and $request.method) {
    continue
  }
  if ($request.id) {
    $jsonResponse = Invoke-HandleRequest -request $request
    [Console]::WriteLine($jsonResponse)
    [Console]::Out.Flush()
  }
}