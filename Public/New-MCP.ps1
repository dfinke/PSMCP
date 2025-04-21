function New-MCP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tools,

        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Validate SourceFile exists
    if (-not (Test-Path -Path $SourceFile -PathType Leaf)) {
        Write-Error "Source file not found: $SourceFile"
        return
    }

    # Construct the path to the template file relative to the module root
    $TemplatePath = Join-Path -Path "$PSScriptRoot\..\template" -ChildPath 'server.template.ps1'

    # Validate Template file exists
    if (-not (Test-Path -Path $TemplatePath -PathType Leaf)) {
        Write-Error "Server template file not found: $TemplatePath"
        return
    }

    # Read the template content
    $templateContent = Get-Content -Path $TemplatePath -Raw

    # Generate tool registration line
    $functionNames = $Tools -join ','
    $toolRegistrations = "Register-Tool -MCP -FunctionName $functionNames"

    # Perform replacements
    # Replace the placeholder ##SOURCE_FILE## with the actual SourceFile path
    # Escape backslashes in the SourceFile path for the replacement string
    $escapedSourceFile = $SourceFile -replace '\\', '\\'
    $outputContent = $templateContent -replace [regex]::Escape('##SOURCE_FILE##'), $escapedSourceFile
    $outputContent = $outputContent -replace [regex]::Escape('$($toolRegistrations)'), $toolRegistrations.Trim()

    # Ensure the output directory exists
    $OutputDirectory = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
        try {
            New-Item -Path $OutputDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Failed to create output directory: $OutputDirectory. Error: $($_.Exception.Message)"
            return
        }
    }

    # Write the modified content to the output path
    try {
        Set-Content -Path $OutputPath -Value $outputContent -Encoding UTF8 -Force -ErrorAction Stop
        Write-Verbose "Successfully created MCP server script at $OutputPath"
    }
    catch {
        Write-Error "Failed to write output file: $OutputPath. Error: $($_.Exception.Message)"
    }
}
