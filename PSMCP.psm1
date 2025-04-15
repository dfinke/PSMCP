# Construct the path to the Public directory
$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'

# Check if the Public directory exists
if (Test-Path -Path $PublicPath -PathType Container) {
    # Get all .ps1 files in the Public directory
    $PublicFiles = Get-ChildItem -Path $PublicPath -Filter *.ps1 -File

    # Dot-source each .ps1 file
    foreach ($File in $PublicFiles) {
        try {
            . $File.FullName
        }
        catch {
            Write-Error "Failed to source file: $($File.FullName). Error: $($_.Exception.Message)"
        }
    }
}
else {
    Write-Warning "Public directory not found at path: $PublicPath"
}