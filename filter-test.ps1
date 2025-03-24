function Filter-TfOutput {
    # define parameters
    param
    (
        [Parameter(ValueFromPipeline)]
        [string]
        $Text,
    
        [ValidateRange(-10, 10)]
        [int]
        $Param1 = 0
    )
  
    # do initialization tasks
    begin {
        $line = 0
        $Mode = 'none'
        $SentinelResult = $null
        $SentinelPolicies = @()
    }
  
    # process pipeline input
    process {
        $line++
        if ($Text -eq 'Organization policy check:') {
            $Mode = 'sentinel'
            Write-Debug "Setting Mode to Sentinel."
            Return
        }

        
        if ($Mode -eq 'sentinel') {
            if ($Text -eq '') {
                Return
            }
            if ($PreviousLine -eq 'value') {
                $PreviousLine = ''
                Return
            }
            if ($PreviousLine -eq 'description') {
                $PreviousLine = ''
                Return
            }

            $Search = $Text | Select-String -Pattern '^Sentinel Result: (true|false)$'
            if ($Search) {
                $SentinelResult = $Search.Matches.Groups[1].Value
                Write-Debug "Detected Sentinel final result: $SentinelResult"
                Return
                Write-Debug "Yoho"
            }

            $Search = $Text | Select-String -Pattern '^##\sPolicy\s+(\d+)\:\s+([a-zA-Z0-9_/\.-]+)\s+\(([a-z-]+)\)'
            if ($Search) {
                $PolicyIx = $Search.Matches.Groups[1].Value
                $PolicyName = $Search.Matches.Groups[2].Value
                $PolicyEnf = $Search.Matches.Groups[3].Value

                $SentinelPolicies += [PsCustomObject]@{
                    Index       = $PolicyIx
                    Name        = $PolicyName
                    Enforcement = $PolicyEnf
                    Result      = $null
                }
                Return
            }

            $Search = $Text | Select-String -Pattern '^Result: (true|false)$'
            if ($Search) {
                $PolicyResult = $Search.Matches.Groups[1].Value

                $SentinelPolicies | ? { $_.Name -eq $PolicyName } | % { $_.Result = $PolicyResult }
                $PolicyName = $null
                $PolicyIx = $null
                $PolicyEnf = $null
                $PolicyResult = $null
                Return
            }

            $Search = $Text | Select-String -Pattern '^\./[a-z0-9_\.]+\.sentinel[\d\:]+ - Rule .*'
            if ($Search) {
                Return
            }
            if ($Text -eq '  Value:') {
                $PreviousLine = 'value'
                Return
            }
            if ($Text -eq '  Description:') {
                $PreviousLine = 'description'
                Return
            }

        }

        Write-Host "${line}: >> $Text"
    }

    # do cleanup tasks
    end {
        Write-Host "Sentinel Check Result: $SentinelResult"
        if ($SentinelResult -eq 'false') {
            $SentinelPolicies
        }
        Write-Host "`nExiting Filter-TfOutput.."
        $global:pol = $SentinelPolicies
        $global:result = $SentinelResult
    }
}

<#
$pol = @{}

$myitems = @(
    [pscustomobject]@{name = "Joe"; age = 32; info = "something about him" },
    [pscustomobject]@{name = "Sue"; age = 29; info = "something about her" },
    [pscustomobject]@{name = "Cat"; age = 12; info = "something else" }
)


$array = @()
$object = New-Object -TypeName PSObject
$object | Add-Member -Name 'Name' -MemberType Noteproperty -Value 'Joe'
$object | Add-Member -Name 'Age' -MemberType Noteproperty -Value 32
$object | Add-Member -Name 'Info' -MemberType Noteproperty -Value 'something about him'
$array += $object
$object = New-Object -TypeName PSObject
$object | Add-Member -Name 'Name' -MemberType Noteproperty -Value 'Helen'
$object | Add-Member -Name 'Age' -MemberType Noteproperty -Value 35
$object | Add-Member -Name 'Info' -MemberType Noteproperty -Value 'Helly R'
$array += $object

$array | Format-Table
#>