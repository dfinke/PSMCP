<#
.SYNOPSIS
Generates an MCP-compatible function call specification for a PowerShell function.

.DESCRIPTION
Mirrors Get-OAIFunctionCallSpec.ps1 but outputs a JSON object compatible with the anthropic MCP Tool definition.

.PARAMETER FunctionName
The name of the function to describe.

.PARAMETER ParameterSet
The parameter set index to use (default 0).

.EXAMPLE
Get-MCPFunctionCallSpec -FunctionName reverse
#>
function Get-MCPFunctionCallSpec {
    param(
        [Parameter(Mandatory)]
        [string[]]$FunctionName,
        [int]$ParameterSet = 0
    )

    $results = [ordered]@{}
    foreach ($fn in $FunctionName) {
        $CommandInfo = try { Get-Command -Name $fn -ErrorAction Stop } catch { $null }
        if ($null -eq $CommandInfo) {
            Write-Warning "$fn not found!"
            continue
        }
        if ($CommandInfo -is [System.Management.Automation.AliasInfo]) {
            $CommandInfo = $CommandInfo.ResolvedCommand
        }
        if ($CommandInfo.ParameterSets.Count -lt $ParameterSet + 1) {
            Write-Error "ParameterSet $ParameterSet does not exist for $fn."
            continue
        }

        $help = Get-Help $CommandInfo.Name
        $description = $help.Synopsis | Out-String
        if (-not $description) {
            $description = $help.Description.Text | Out-String
        }
        $description = $description.Trim()
        if (-not $description) {
            Write-Error "Function '$fn' does not have a description (Synopsis or Description in comment-based help). Aborting." -ErrorAction Stop
            continue
        }

        $Parameters = $CommandInfo.ParameterSets[$ParameterSet].Parameters |
        Where-Object { $_.Name -notmatch 'Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable|WhatIf|Confirm|NoHyperLinkConversion|ProgressAction' }

        $inputSchema = [ordered]@{
            type       = 'object'
            properties = [ordered]@{}
            required   = @()
        }
        foreach ($Parameter in $Parameters) {
            $typeName = $Parameter.ParameterType.Name.ToLower()
            switch ($typeName) {
                'string' { $type = 'string' }
                'int32' { $type = 'integer' }
                'int64' { $type = 'integer' }
                'boolean' { $type = 'boolean' }
                'switchparameter' { $type = 'boolean' }
                default { $type = 'string' }
            }
            try {
                $paramHelp = (Get-Help $CommandInfo.Name -Parameter $Parameter.Name -ErrorAction Stop).Description.Text | Out-String
            }
            catch { $paramHelp = $null }
            $paramHelp = $paramHelp ? $paramHelp.Trim() : "No description available for this parameter."
            $inputSchema.properties[$Parameter.Name] = @{ type = $type; description = $paramHelp }
            if ($Parameter.IsMandatory) {
                $inputSchema.required += $Parameter.Name
            }
        }

        # Set returns to use the function's description
        $returns = @{ type = 'string'; description = $description }

        $results[$CommandInfo.Name] = [ordered]@{
            name        = $CommandInfo.Name
            description = $description
            inputSchema = $inputSchema
            returns     = $returns
        }
    }

    $results | ConvertTo-Json -Depth 8
}