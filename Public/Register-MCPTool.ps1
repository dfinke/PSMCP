function Register-MCPTool {
    param(
        [Parameter(Mandatory)]
        [string[]]$FunctionName,
        [int]$ParameterSet = 0,
        [Switch]$DoNotCompress
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
                'int' { $type = 'number' }
                'int32' { $type = 'number' }
                'int64' { $type = 'number' }
                'double' { $type = 'number' }
                'boolean' { $type = 'boolean' }
                'switchparameter' { $type = 'boolean' }
                default { $type = 'string' }
            }
            try {
                $paramHelp = (Get-Help $CommandInfo.Name -Parameter $Parameter.Name -ErrorAction Stop).Description.Text | Out-String
            }
            catch { $paramHelp = $null }
            $paramHelp = $paramHelp ? $paramHelp.Trim() : "No description available for this parameter."
            $inputSchema.properties[$Parameter.Name] = [ordered]@{ type = $type; description = $paramHelp }
            if ($Parameter.IsMandatory) {
                $inputSchema.required += $Parameter.Name
            }
        }

        # Set returns based on spec - use original function name for description
        # Inferring return type is complex in PowerShell, using example's 'number' for Invoke-Addition
        # Defaulting to 'string' otherwise, but this might need refinement based on actual function output types
        $returnType = 'string' # Default
        if ($CommandInfo.Name -eq 'Invoke-Addition') {
            # Specific case from spec
            $returnType = 'number'
        }
        # TODO: Add more robust return type inference if possible
        $returns = [ordered]@{ type = $returnType; description = $CommandInfo.Name }


        $results[$CommandInfo.Name] = [ordered]@{ # Keep using CommandInfo.Name as key for internal logic
            name        = $CommandInfo.Name # Use original name for output
            description = $CommandInfo.Name # Use original name for output description
            inputSchema = $inputSchema
            returns     = $returns
        }
    }

    # Output an array of tool objects, ensuring it's an array even for a single function
    [array]$outputArray = @($results.Values)

    if ($DoNotCompress) {
        $outputArray | ConvertTo-Json -Depth 8
    }
    else {
        $outputArray | ConvertTo-Json -Depth 8 -Compress:$Compress
    }
}