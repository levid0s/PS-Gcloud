function npp {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$InputObject
    )

    begin {
        $content = ""
    }

    process {
        $content += $_ + "`n"
    }

    end {
        Write-Host $Content
    }
}
