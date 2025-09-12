param(
    # Accept any pipeline input
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $InputObject,

    # Optional: store the full (unmodified) content in a variable in the caller's scope
    [string] $Variable
)
begin {
    # Buffer for all incoming content
    $buffer = New-Object System.Text.StringBuilder
}
process {
    # Format input like the pipeline would display and capture *all* lines
    foreach ($line in ($InputObject | Out-String -Stream)) {
        # Append without trailing CR/LF duplication
        $null = $buffer.AppendLine($line.TrimEnd("`r", "`n"))
    }
}
end {
    # Get full captured content (may be empty)
    $content = $buffer.ToString()

    # Optionally store raw content in caller scope
    if ($PSBoundParameters.ContainsKey('Variable')) {
        Set-Variable -Name $Variable -Scope 1 -Value $content
    }

    # If nothing was received, output nothing
    if ([string]::IsNullOrEmpty($content)) { return }

    # Emit lines with '>> ' prefix
    ($content -split '\r\n|\n|\r') | ForEach-Object { ">> $_" }
}
