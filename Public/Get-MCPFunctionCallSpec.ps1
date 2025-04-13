<#
.SYNOPSIS
Generates an MCP specification for a given PowerShell cmdlet.

.DESCRIPTION
The Get-MCPFunctionCallSpec function generates a Model Context Protocol (MCP) specification for a specified PowerShell cmdlet. 
It retrieves the cmdlet\'s parameters and their details, and optionally returns the specification in hash or JSON format.

.PARAMETER CmdletName
The name of the cmdlet for which to generate the specification.

.PARAMETER Strict
If specified, the generated specification will not allow additional properties in the input schema.

.PARAMETER ParameterSet
The ParameterSet to use. Defaults to 0. Iterate according to documentation.

.PARAMETER ReturnJson
If specified, the function returns the specification in JSON format.

.PARAMETER ClearRequired
If specified, the function will not mark mandatory parameters as required in the input schema.

.PARAMETER Mcp
If specified, all parameters will be marked as required in the input schema.

.EXAMPLE
Get-MCPFunctionCallSpec -CmdletName Get-Process -ReturnJson

This command generates a JSON MCP specification for the Get-Process cmdlet.

.EXAMPLE
Get-MCPFunctionCallSpec -CmdletName Invoke-WebRequest -Mcp

This command generates an MCP specification for Invoke-WebRequest where all parameters are marked as required.

#>

function Get-MCPFunctionCallSpec {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string]$CmdletName,
        [switch]$Strict,
        [Parameter(HelpMessage = "The ParameterSet to use. Iterate according to documentation")]
        [int]$ParameterSet = 0,
        [switch]$ReturnJson,
        [switch]$ClearRequired        
    )
    
    begin {
        $CommandInfo = try { Get-Command -Name $CmdletName -ErrorAction Stop } catch { $null }
        if ($null -eq $CommandInfo) {
            Write-Warning "$CmdletName not found!"
            return $null
        }
        if ($CommandInfo -is [System.Management.Automation.AliasInfo]) {
            Write-Verbose "$CmdletName is an alias for $($CommandInfo.ResolvedCommand.Name)"
            $CommandInfo = $CommandInfo.ResolvedCommand
        }
        if ($CommandInfo.ParameterSets.Count -lt $parameterset + 1) {
            Write-Error "ParameterSet $ParameterSet does not exist for $CmdletName. These ParameterSets are available: $($CommandInfo.ParameterSets.Name -join ', ')" -ErrorAction Stop
        }
        Write-Verbose "Preparing to generate MCP specification for $CmdletName ParameterSet $($CommandInfo.ParameterSets[$ParameterSet].Name)"
    }
    
    process {
        # Assuming only one command info object
        $Command = $CommandInfo[0] 
        
        # FunctionSpec scaffold:
        Write-Verbose "Generating MCP specification for $($Command.Name)"
        $help = Get-Help $Command.Name -ErrorAction SilentlyContinue
        $description = $help.description.text | Out-String -Stream
        if ($description.Length -gt 1024) {
            $description = $description.Substring(0, 1024)
        }
        
        $FunctionSpec = [ordered]@{
            name        = $Command.Name
            description = $description
            inputSchema = [ordered]@{
                type       = 'object'
                properties = [ordered]@{}
                required   = [System.Collections.Generic.List[string]]@()
            }
            # Placeholder for returns, will attempt to populate later
            returns     = [ordered]@{ 
                type        = 'object' # Default or placeholder type
                description = 'Output object' # Generic description
            } 
        }

        if (!$help.description.text) {
            $FunctionSpec.Remove("description")
        }

        if ($Strict) {
            $FunctionSpec.inputSchema["additionalProperties"] = $false
            # Note: MCP spec doesn't have a top-level 'strict' property like the example, 
            # 'additionalProperties' in inputSchema handles this.
        }
        
        $Parameters = $Command.ParameterSets[$ParameterSet].Parameters | Where-Object {
            $_.Name -notmatch 'Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable|WhatIf|Confirm|NoHyperLinkConversion|ProgressAction'
        } | Select-Object Name, ParameterType, IsMandatory, HelpMessage, Attributes -Unique
        
        foreach ($Parameter in $Parameters) {
            # Assuming Get-ToolProperty exists and works similarly
            $property = Get-ToolProperty $Parameter 
            if ($null -eq $property) {
                Write-Verbose "No type translation found for $($Parameter.Name). Type is $($Parameter.ParameterType)"
                continue
            }
            try {
                $ParameterDescription = Get-Help $Command.Name -Parameter $Parameter.Name -ErrorAction Stop |
                Select-Object -ExpandProperty Description -ErrorAction Stop |
                Select-Object -ExpandProperty Text -ErrorAction Stop | Out-String -Stream
            }
            catch { Write-Verbose "No description found for $($Parameter.Name)" }
            
            if ($ParameterDescription) {
                $property['description'] = $ParameterDescription.Trim()
            }
            if ($property) { $FunctionSpec.inputSchema.properties.Add($Parameter.Name, $property) }
            
            $FunctionSpec.inputSchema.required.Add($Parameter.Name)
        }

        # Attempt to determine return type from OutputType attribute
        if ($Command.OutputType.Count -gt 0) {
            # For simplicity, taking the first output type. Might need refinement for multiple types.
            $outputType = $Command.OutputType[0].Type.Name
            $returnTypeSchema = switch ($outputType) {
                'String' { @{ type = 'string'; description = 'Output string' } }
                'Int32' { @{ type = 'integer'; format = 'int32'; description = 'Output integer' } }
                'Int64' { @{ type = 'integer'; format = 'int64'; description = 'Output long integer' } }
                'Boolean' { @{ type = 'boolean'; description = 'Output boolean' } }
                'Double' { @{ type = 'number'; format = 'double'; description = 'Output double' } }
                'Float' { @{ type = 'number'; format = 'float'; description = 'Output float' } }
                'DateTime' { @{ type = 'string'; format = 'date-time'; description = 'Output date/time string' } }
                # Add more type mappings as needed
                default { @{ type = 'object'; description = "Output object of type $($outputType)" } }
            }
            $FunctionSpec.returns = $returnTypeSchema
        }
        else {
            $FunctionSpec.returns = @{ type = 'object'; description = 'Output object (type not specified)' }
        }


        # MCP structure doesn't wrap the function spec in 'function' key like OpenAI spec
        $result = $FunctionSpec 

        if ($ReturnJson) {
            return ($result | ConvertTo-Json -Depth 10)
        }
        $result
    }
    
    end {
        
    }
}
