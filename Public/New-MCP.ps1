Class TemplateNames : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        $templates = foreach ($template in Get-ChildItem $PSScriptRoot\..\template) {
            $template.BaseName -replace '.template', ''
        }
        
        return $templates
    }
}

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

        [ValidateSet([TemplateNames])]
        [string]$template,

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
            # If Path is specified, check if it's an absolute path or a special path like TestDrive:
            if ([System.IO.Path]::IsPathRooted($Path) -or $Path -like "TestDrive:*") {
                $TargetDirectoryPath = $Path
            }
            else {
                # If not absolute, resolve it relative to the current directory
                $TargetDirectoryPath = Join-Path -Path (Get-Location).Path -ChildPath $Path
            }
        }

        # Resolve the final target directory path
        $TargetDirectory = Resolve-Path -Path $TargetDirectoryPath -ErrorAction SilentlyContinue
        if (-not $TargetDirectory) {
            # If path doesn't exist after resolving, treat it as a new directory to be created
            $TargetDirectory = $TargetDirectoryPath
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

        if (-not $template) {
            $template = "server"
        }
        
        $templatePath = "template\$($template).template.ps1"

        # $TemplatePath = Join-Path -Path $ModuleRoot -ChildPath "template\server.template.ps1"
        $TemplatePath = Join-Path -Path $ModuleRoot -ChildPath $templatePath

        if (-not (Test-Path -Path $TemplatePath -PathType Leaf)) {
            throw "Server template file not found at '$TemplatePath'."
        }
    }

    process {
        $directoryExisted = Test-Path -Path $TargetDirectory -PathType Container
        $containsMcpFiles = $false
        $isEmpty = $false

        if ($directoryExisted) {
            Write-Verbose "Directory '$TargetDirectory' already exists."
            # Check for specific MCP files
            $containsMcpFiles = (Test-Path -Path $McpJsonPath -PathType Leaf) -or (Test-Path -Path $ServerScriptPath -PathType Leaf)
            # Check if the directory is empty (ignoring hidden/system items potentially)
            $isEmpty = (Get-ChildItem -Path $TargetDirectory -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0

            if ($containsMcpFiles -and -not $Force) {
                # It exists AND looks like an MCP project AND -Force is not used
                Write-Error "Directory '$TargetDirectory' already contains MCP configuration files (mcp.json or $($ServerName).ps1). Use -Force to overwrite."
                return # Stop execution
            }
            # If it exists but is empty, or doesn't contain MCP files, or -Force is used, we proceed.
            # Informational message will be printed after directory is confirmed/created.
        }
        else {
            # Directory does not exist, create it
            if ($PSCmdlet.ShouldProcess($TargetDirectory, "Create directory")) {
                New-Item -Path $TargetDirectory -ItemType Directory -Force:$Force | Out-Null
            }
            else {
                Write-Warning "Directory creation skipped by user."
                return
            }
        }

        # --- Point where directory is guaranteed to exist ---

        # Print informational message *before* creating/overwriting files
        if ($directoryExisted) {
            # Use $isEmpty here
            if ($isEmpty -or !$containsMcpFiles) {
                Write-Host "Initialized MCP project in existing directory '$TargetDirectory'."
            } 
            # If it contained MCP files and -Force was used, the file-level warnings/overwrites will occur.
            # A specific message here might be redundant or slightly confusing depending on which files get overwritten.
        }
        else {
            Write-Host "Initialized MCP project in new directory '$TargetDirectory'."
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
                "-NoProfile",
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
    }
}