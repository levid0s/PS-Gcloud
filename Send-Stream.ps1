[CmdletBinding()]
param(
    # Accept any pipeline input
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $InputObject,

    # Optional: explicitly provide the path to Notepad++ (e.g., "C:\Program Files\Notepad++\notepad++.exe")
    [string] $Program,

    # Optional: also echo the prefixed lines back to the console while writing to file
    [switch] $AlsoEcho,

    # Optional: choose a custom prefix (default is ">> ")
    [string] $Prefix = '',

    [string] $FileType = "txt"
)

begin {
    # Create a readable temp file name in %TEMP%
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFile = Join-Path $tempDir ("Show-Stream_{0:yyyyMMdd-HHmmss-fff}.$FileType" -f (Get-Date))

    # Prepare a StreamWriter for UTF-8 with BOM (friendly with most editors)
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    $script:sw = New-Object System.IO.StreamWriter($tempFile, $false, $utf8WithBom)

    Write-Verbose "Writing stream to $tempFile"
}

process {
    # Format incoming objects like the pipeline would display them
    foreach ($s in ($InputObject | Out-String -Stream)) {
        # Normalize line endings and prefix
        $line = $s.TrimEnd("`r", "`n")
        $prefixed = "{0}{1}" -f $Prefix, $line

        # Write to file as we go
        $script:sw.WriteLine($prefixed)
        $script:sw.Flush()

        # Optionally also emit to the console/pipeline
        if ($AlsoEcho) { $prefixed }
    }
}

end {
    # Close the writer
    if ($script:sw) { $script:sw.Dispose() }

    # Try to locate Notepad++
    $npp = $null
    if ($Program) {
        if (Get-Command $Program) { $npp = $Program }
        else { Write-Warning "Program '$Program' not found. Will try to auto-detect Notepad++." }
    }
    if (-not $npp) {
        $cmd = Get-Command "notepad++.exe" -ErrorAction SilentlyContinue
        if ($cmd) { $npp = $cmd.Source }
    }
    if (-not $npp) {
        $candidates = @(
            "$env:ProgramFiles\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
        )
        $npp = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    # Launch editor (fallback to Notepad if Notepad++ not found)
    if ($npp) {
        # Start-Process -FilePath $npp -ArgumentList @("`"$tempFile`"")
        & $npp $tempFile
    }
    else {
        Write-Warning "Notepad++ not found. Opening with Notepad."
        Start-Process -FilePath "notepad.exe" -ArgumentList @("`"$tempFile`"")
    }

    # Return the temp file path so you have it programmatically if needed
    $tempFile
}
