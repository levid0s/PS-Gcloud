[CmdletBinding()]
param(
    [Switch]$Refresh,
    [String]$Application,
    [Switch]$Excel,
    [Switch]$PassThruExcel,
    [Switch]$Extended
)

$StateFile = "${env:TEMP}\ps-gcloud-projects-list.json"

if (($Refresh -eq $true) -or -not (Test-Path $StateFile)) {
    Write-Information -InformationAction Continue "Refreshing project list"
    $pjson = $(gcloud projects list --format=json)

    if ($LASTEXITCODE -ne 0) {
        Throw "Failed: gcloud projects list --format=json"
    }

    Set-Content -Path $StateFile -Value $pjson -Encoding UTF8
}
else {
    # Get Last Modified Date of file
    $lastModified = (Get-Item $StateFile).LastWriteTime
    Write-Information -InformationAction Continue "Using cached data from: $lastModified"

    $pjson = Get-Content -Path $StateFile -Encoding UTF8 -Raw -ErrorAction Stop
}

$p0 = $pjson | ConvertFrom-Json

if ($Application) {
    $p0 = $p0 | Where-Object { $_.labels.application -like "${Application}*" }
}

$proj = $p0 | Select-Object `
    name, `
    projectId, `
    projectNumber, `
    createTime, `
    lifecycleState, `
@{Name = 'labels_application'; Expression = { $_.labels.application } }, `
@{Name = 'labels_env'; Expression = { $_.labels.env } }, `
@{Name = 'labels_cmdb_id'; Expression = { $_.labels.cmdb_id } }, `
@{Name = 'labels_owner'; Expression = { $_.labels.owner } }, `
@{Name = 'labels_cost_center'; Expression = { $_.labels.cost_center } }, `
@{Name = 'labels_project_code'; Expression = { $_.labels.project_code } }, `
@{Name = 'labels_app_svc_name'; Expression = { $_.labels.app_svc_name } }, `
@{Name = 'labels_app_svc_id'; Expression = { $_.labels.app_svc_id } }, `
@{Name = 'parent_id'; Expression = { $_.parent.id } }, `
@{Name = 'parent_type'; Expression = { $_.parent.type } }

if (-Not $Extended) {
    $proj = $proj | Select-Object `
        labels_application, `
        labels_env, `
        name, `
        projectId, `
        projectNumber, `
        parent_id, `
        createTime | Sort-Object -Property labels_application, labels_env
}

$global:proj = $proj
Write-Host "Exported var: `$proj"

if ($Excel) {
    function Add-Columns {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)][Microsoft.Office.Interop.Excel.ApplicationClass]$Excel,
            [Parameter(Mandatory = $true)]$Columns
        )

        $workbook = $excel.Workbooks | Select-Object -First 1
        $worksheet = $workbook.worksheets.Item(1)
        $table = $worksheet.ListObjects.Item("Projects")

        $count = 5
        foreach ($column in $Columns) {
            $worksheet.Columns.Item($count).Insert() | Out-Null
            $projectLinkColumn = $table.ListColumns.Item($count)
            $projectLinkColumn.Name = $column.Name
            $projectLinkColumn.DataBodyRange.NumberFormat = "General"
            $projectLinkColumn.DataBodyRange.Formula = $column.Formula
            $count++
        }            
    }

    $Columns = @(
        [PSCustomObject]@{ Name = 'Project Link'; Formula = '=HYPERLINK("https://console.cloud.google.com/home/dashboard?inv=1&invt=AbqiZQ&project="&[@projectId],[@projectId])' },
        [PSCustomObject]@{ Name = 'Compute'; Formula = '=HYPERLINK("https://console.cloud.google.com/compute/instances?inv=1&invt=AbqiZQ&project="&[@projectId],"Compute")' },
        [PSCustomObject]@{ Name = 'SQL'; Formula = '=HYPERLINK("https://console.cloud.google.com/sql/instances?inv=1&invt=AbqiZQ&project="&[@projectId],"SQL")' },
        [PSCustomObject]@{ Name = 'IAM'; Formula = '=HYPERLINK("https://console.cloud.google.com/iam-admin/iam?inv=1&invt=AbqiZQ&project="&[@projectId],"IAM")' },
        [PSCustomObject]@{ Name = 'Logs'; Formula = '=HYPERLINK("https://console.cloud.google.com/logs/query;duration=PT15M?inv=1&invt=AbqiZQ&project="&[@projectId],"Logs")' }
    )
  
    Remove-Variable Excel
    $Excel = $proj | Export-Excel -PassThru
    
    Add-Columns -Excel $Excel -Columns $Columns
    
    $workbook = $excel.Workbooks | Select-Object -First 1
    $worksheet = $workbook.worksheets.Item(1)
    
    $range = $worksheet.Range("A1").CurrentRegion    
    $range.EntireColumn.Autofit() | Out-Null
    $worksheet.Columns.Item(4).Hidden = $true
    
    if ($PassThruExcel) {
        return $Excel
    }
    else {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
}
else {
    $proj | Out-GridView
}
