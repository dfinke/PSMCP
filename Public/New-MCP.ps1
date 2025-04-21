function New-MCP {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Path, # Removed default value

        [Parameter()]
        [string]
        $ServerName = "MCPServer",

        [Parameter()]
        [switch]
        $Force
    )

    begin {
        # Determine the target directory
        $TargetDirectoryPath = $null
        if ([string]::IsNullOrEmpty($Path)) {
            # If Path is not specified, use the current directory
            $TargetDirectoryPath = (Get-Location).Path
            Write-Verbose "No -Path specified, using current directory: $TargetDirectoryPath"
        }
        else {
            # If Path is specified, resolve it
            $TargetDirectoryPath = $Path
        }

        # Resolve the final target directory path
        $TargetDirectory = Resolve-Path -Path $TargetDirectoryPath -ErrorAction SilentlyContinue
        if (-not $TargetDirectory) {
            # If path doesn't exist after resolving, treat it as a new directory to be created
            $TargetDirectory = Join-Path -Path (Get-Location).Path -ChildPath $TargetDirectoryPath # Use original path specifier for joining
            Write-Verbose "Target directory '$TargetDirectory' does not exist. It will be created."
        }
        elseif (Test-Path -Path $TargetDirectory -PathType Leaf) {
            throw "The specified path '$TargetDirectory' exists but is a file, not a directory."
        }

        # Construct paths for files and directories directly within the target directory
        $VscodeFolderPath = Join-Path -Path $TargetDirectory -ChildPath ".vscode"
        $McpJsonPath = Join-Path -Path $VscodeFolderPath -ChildPath "mcp.json"
        $ServerScriptPath = Join-Path -Path $TargetDirectory -ChildPath "$($ServerName).ps1"

        # Determine the script's directory
        $ScriptDirectory = Split-Path -Path $PSCommandPath -Parent

        # Determine the module root (one level up from Public)
        $ModuleRoot = Split-Path -Path $ScriptDirectory -Parent

        # Construct the template path
        $TemplatePath = Join-Path -Path $ModuleRoot -ChildPath "template\server.template.ps1"

        if (-not (Test-Path -Path $TemplatePath -PathType Leaf)) {
            throw "Server template file not found at '$TemplatePath'."
        }
    }

    process {
        # 1. Create server directory
        if (Test-Path -Path $TargetDirectory -PathType Container) {
            Write-Verbose "Directory '$TargetDirectory' already exists."
            if (-not $Force) {
                Write-Warning "Directory '$TargetDirectory' already exists. Use -Force to potentially overwrite contents."
                # Continue to create files inside if they don't exist or if -Force is specified
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($TargetDirectory, "Create directory")) {
                New-Item -Path $TargetDirectory -ItemType Directory -Force:$Force | Out-Null # Use Force in case parent exists but target doesn't
            }
            else {
                # If user chose No for ShouldProcess on directory creation, stop
                Write-Warning "Directory creation skipped by user."
                return
            }
        }

        # 2. Create .vscode directory
        if (-not (Test-Path -Path $VscodeFolderPath -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($VscodeFolderPath, "Create directory '.vscode'")) {
                New-Item -Path $VscodeFolderPath -ItemType Directory | Out-Null
            }
        }
        else {
            Write-Verbose "Directory '$VscodeFolderPath' already exists."
        }

        # 3. Create mcp.json
        $mcpJsonContent = @'
{
    "servers": {
        "mcp-powershell-{servername}": {
            "type": "stdio",
            "command": "pwsh",
            "args": [                
                "-Command",
                "${workspaceFolder}\\{scriptname}.ps1"
            ]
        }
    }
}
'@ -replace '\{servername\}', $ServerName -replace '\{scriptname\}', $ServerName

        if (Test-Path -Path $McpJsonPath -PathType Leaf) {
            Write-Verbose "File '$McpJsonPath' already exists."
            if (-not $Force) {
                Write-Warning "File '$McpJsonPath' already exists. Use -Force to overwrite."
            }
            elseif ($PSCmdlet.ShouldProcess($McpJsonPath, "Overwrite file 'mcp.json'")) {
                Set-Content -Path $McpJsonPath -Value $mcpJsonContent -Force
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($McpJsonPath, "Create file 'mcp.json'")) {
                # Ensure parent directory exists before writing file
                if (-not (Test-Path -Path $VscodeFolderPath -PathType Container)) {
                    New-Item -Path $VscodeFolderPath -ItemType Directory | Out-Null
                }
                Set-Content -Path $McpJsonPath -Value $mcpJsonContent
            }
        }

        # 4. Create $ServerName.ps1 from template
        $templateContent = Get-Content -Path $TemplatePath -Raw
        # Potentially add replacements to the template content here if needed in the future

        if (Test-Path -Path $ServerScriptPath -PathType Leaf) {
            Write-Verbose "File '$ServerScriptPath' already exists."
            if (-not $Force) {
                Write-Warning "File '$ServerScriptPath' already exists. Use -Force to overwrite."
            }
            elseif ($PSCmdlet.ShouldProcess($ServerScriptPath, "Overwrite file '$($ServerName).ps1'")) {
                Set-Content -Path $ServerScriptPath -Value $templateContent -Force
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($ServerScriptPath, "Create file '$($ServerName).ps1'")) {
                Set-Content -Path $ServerScriptPath -Value $templateContent
            }
        }

        # Output the directory info object if it was created or existed
        if (Test-Path -Path $TargetDirectory -PathType Container) {
            Get-Item -Path $TargetDirectory
        }
    }
}