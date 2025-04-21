create a New-MCP function
- in its own file
- parameters
    - Path - Path to where the MCP server is setup. Default to the current directory.
    - ServerName - Name of the MCP server. Default to "MCPServer".
What it does
- Creates a new directory for the MCP server if it doesn't exist.
- Creates a .vscode folder in the MCP server directory.
- Creates an mcp.json file in the MCP server directory.
    - hw.ps1 is replaced with the $ServerName
    - `mcp-server` is replaced with the `mcp-powershell-$($ServerName)`

    ```json
    {
        "servers": {
            "mcp-server": {
                "type": "stdio",
                "command": "pwsh",
                "args": [
                    "-Command",
                    "${workspaceFolder}\\hw.ps1"
                ]
            }
        }
    }
    ```

- Creates a ps1 file in the MCP server directory named $ServerName.ps1.
    - the file content is pulled in from the /template directory, server.template.ps1

## Potential Enhancements / Considerations

- **Path Parameter Clarity:** Specify if `$Path` refers to the parent directory or the exact server directory to be created.
- **Error Handling / Overwriting:** Add a `-Force` switch parameter to allow overwriting existing directories or files.
- **Template Path:** Ensure the function reliably finds `template\server.template.ps1` relative to the module's installation path (e.g., using `$PSScriptRoot`).
- **JSON Handling:** Consider using `ConvertFrom-Json` and `ConvertTo-Json` for modifying `mcp.json` instead of string replacement for better robustness.
- **Standard Parameters:** Implement `-Verbose` and `-WhatIf` support for better user experience and adherence to PowerShell best practices.
- **Output:** Define a clear return value, such as the path to the created server directory.