function Get-MCPTemplate {
    Get-ChildItem $PSScriptRoot\..\template\ | ForEach-Object {
        [PSCustomObject]@{
            Name    = $_.Name
            Content = Get-Content $_.FullName -Raw
        }
    }
}