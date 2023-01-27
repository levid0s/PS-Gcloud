<#
  .SYNOPSIS
    PowerShell wrapper for Gcloud CLI, v2023.01.27

  .DESCRIPTION
    PowerShell wrapper for Gcloud CLI. Handy because of the autocomplete, sensible defaults, very brief commands, wildcard matching, targetting multiple resources, and more.

    Apologies for the spaghetti code. I am planning to rewrite this soon.

  .EXAMPLE
    Brief list of all the possibilities, please see other examples for more details.
    Responses can be provided at the prompt (eg: C:web="cat /etc/passwd"), or as script parameter as seen below:
    Pressing Enter at the prompt will re-execute the listing. Handy to see if a VM is starting up, etc.

    .\PS-Gcloud.ps1                             # List compute instances and prompt for an action. The action can be typed on the screen, or provided to the script as a parameter.
    .\PS-Gcloud.ps1 1                           # Default action [SSH] for the resource on index 1
    .\PS-Gcloud.ps1 S1                          # SSH on the VM with index 1 in the table
    .\PS-Gcloud.ps1 -UseInternalIpSsh $true     # Connect using internal IP instead of IAP tunnel. Defaults to `true` when the computer is in a domain.
    .\PS-Gcloud.ps1 S:web                       # SSH onto all VMs with "web" in the name.
    .\PS-Gcloud.ps1 S:*                         # SSH onto all VMs in the current project.
    .\PS-Gcloud.ps1 X:web="sudo reboot now"     # Execute `sudo reboot now` on all hosts with "web" in the name, opening new windows for each session. Don't try this is prod.
    .\PS-Gcloud.ps1 C:web="cat /etc/passwd"     # Execute in-line `cat /etc/passwd` on all hosts with "web" in the name, sequentially in the current shell (no new window).
    .\PS-Gcloud.ps1 D1                          # Describe VM1 in yaml format
    .\PS-Gcloud.ps1 Q                           # Qnly do a listing of the VMs and quit.
    .\PS-Gcloud.ps1 ^1=c:\windows               # Upload the c:\windows directory to /tmp/windows on VM1
    .\PS-Gcloud.ps1 ^:*=hello.txt               # Upload `./hello.txt` to all VMs in the project
    .\PS-Gcloud.ps1 v1=/etc/passwd              # Download /etc/passwd file from VM1 to ./{hostname}-passwd-{timestamp} directory
    .\PS-Gcloud.ps1 v:web=/var/log/             # Trailing `/` will indicate the target is folder, ie recursive opration. Download folder for *web* VMs
    .\PS-Gcloud.ps1 -Configurations q           # List configurations and quit
    .\PS-Gcloud.ps1 -ResourceType Disks         # Do stuff with disks like Describe, Snapshot, Delete, Detach, Attach
    .\PS-Gcloud.ps1 -Disks                      # Shorthand switch for -ResourceType Disks. There's a shorthand switch for each ResourceType
    .\PS-Gcloud.ps1 -Disks a4="consumer-testvm" # Attach disk 4 to the VM named `consumer-testvm`
    .\PS-Gcloud.ps1 -Install                    # Add the location of the script in the user %PATH%
    $vms = .\PS-Gcloud.ps1 -ReturnAs-Object     # Return the list of VMs as object. It is not the entire GCP resource though, only has the details from the table.
    .\PS-Gcloud.ps1 -SelfLink                   # Add the relative self_link column to the selection table

    .\PS-Gcloud.ps1 -Disks a1=consumer-testvm -Show-Command   # Show the equivalent gcloud command instead of executing it
#>

param(
  [Parameter()][ValidateSet('Backend-Services', 'Compute', 'Configurations', 'Disks', 'Firewall', 'MIG', 'Snapshots', 'SQL', 'Storage')][string[]]$ResourceType,
  [nullable[bool]]$UseInternalIpSsh,
  [Parameter(Position = 0)][string]$Answer,
  [Switch]$Install,
  [Switch]${Show-Command},
  [Switch]${ReturnAs-Object},
  [Switch]${SelfLink},
  [Switch]${Uri},
  [Switch]${Backend-Services},
  [Switch]$Compute,
  [Switch]$Configurations,
  [Switch]$Disks,
  [Switch]$Firewall,
  [Switch]$MIG,
  [Switch]$Snapshots,
  [Switch]$SQL,
  [Switch]$Storage,
  [Switch]$Help,
  [Switch]$HelpFull
)

if ($Help) {
  Write-Host @'
Brief list of all the possibilities, please see other examples for more details.
Responses can be provided at the prompt (eg: C:web="cat /etc/passwd"), or as script parameter as seen below:
Pressing Enter at the prompt will re-execute the listing. Handy to see if a VM is starting up, etc.

.\PS-Gcloud.ps1                             # List compute instances and prompt for an action. The action can be typed on the screen, or provided to the script as a parameter.
.\PS-Gcloud.ps1 1                           # Default action [SSH] for the resource on index 1
.\PS-Gcloud.ps1 S1                          # SSH on the VM with index 1 in the table
.\PS-Gcloud.ps1 -UseInternalIpSsh $true     # Connect using internal IP instead of IAP tunnel. Defaults to `true` when the computer is in a domain.
.\PS-Gcloud.ps1 S:web                       # SSH onto all VMs with "web" in the name.
.\PS-Gcloud.ps1 S:*                         # SSH onto all VMs in the current project.
.\PS-Gcloud.ps1 X:web="sudo reboot now"     # Execute `sudo reboot now` on all hosts with "web" in the name, opening new windows for each session. Don't try this is prod.
.\PS-Gcloud.ps1 C:web="cat /etc/passwd"     # Execute in-line `cat /etc/passwd` on all hosts with "web" in the name, sequentially in the current shell (no new window).
.\PS-Gcloud.ps1 D1                          # Describe VM1 in yaml format
.\PS-Gcloud.ps1 Q                           # Qnly do a listing of the VMs and quit.
.\PS-Gcloud.ps1 ^1=c:\windows               # Upload the c:\windows directory to /tmp/windows on VM1
.\PS-Gcloud.ps1 ^:*=hello.txt               # Upload `./hello.txt` to all VMs in the project
.\PS-Gcloud.ps1 v1=/etc/passwd              # Download /etc/passwd file from VM1 to ./{hostname}-passwd-{timestamp} directory
.\PS-Gcloud.ps1 v:web=/var/log/             # Trailing `/` will indicate the target is folder, ie recursive opration. Download folder for *web* VMs
.\PS-Gcloud.ps1 -Configurations q           # List configurations and quit
.\PS-Gcloud.ps1 -ResourceType Disks         # Do stuff with disks like Describe, Snapshot, Delete, Detach, Attach
.\PS-Gcloud.ps1 -Disks                      # Shorthand switch for -ResourceType Disks. There's a shorthand switch for each ResourceType
.\PS-Gcloud.ps1 -Disks a4="consumer-testvm" # Attach disk 4 to the VM named `consumer-testvm`
.\PS-Gcloud.ps1 -Install                    # Add the location of the script in the user %PATH%
$vms = .\PS-Gcloud.ps1 -ReturnAs-Object     # Returns the initial resource listing as object. The action will not be executed though.
.\PS-Gcloud.ps1 -SelfLink                   # Add the relative self_link column to the selection table

.\PS-Gcloud.ps1 -Disks a1=consumer-testvm -Show-Command   # Show the equivalent gcloud command instead of executing it
'@

}
if ($HelpFull) {
  Get-Help .\PS-Gcloud.ps1 -Full
  exit
}

$ResourceTypes = @('Backend-Services', 'Compute', 'Configurations', 'Disks', 'Firewall', 'MIG', 'Snapshots', 'SQL', 'Storage')
$SelfLink = $SelfLink -or $Uri

# Alternative parameter validation
if ($ResourceType -eq $null) {
  foreach ($rt in $ResourceTypes) {
    $rtval = Invoke-Expression "`${$rt}"
    if ($rtval -eq $true) {
      $ResourceType = $rt
      break
    }
  }
  if ($ResourceType -eq $null) {
    $ResourceType = $ResourceTypes[0] # Default Resource Type is Compute
  }
}

function Get-EnvPathsArr {
  Param([ValidateSet('User', 'Machine', 'All')]$Scope = 'All')

  $Paths = @() 
  if ( @('Machine', 'All') -icontains $Scope) {
    $Paths += `
      [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
  }
 
  if ( @('User', 'All') -icontains $Scope) {
    $Paths += `
      [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
  }

  return $Paths
}


$Sel = $null

# $env:PATH="d:\src\do-compute;$env:path"
if ($Install -eq $true -and ![string]::IsNullOrEmpty($PSScriptRoot)) {
  if (Get-EnvPathsArr('All') -notcontains $PSScriptRoot) {
    Write-Output 'INSTALL: Adding script location to %PATH% as user env var...'

    [Environment]::SetEnvironmentVariable("Path", "$((Get-EnvPathsArr('User')) -join ';');$PSScriptRoot", [System.EnvironmentVariableTarget]::User)
  }

  if ($env:Path -split ';' -notcontains $PSScriptRoot) {
    Write-Output 'INSTALL: Refreshing %PATH% in current shell...'
    $env:Path = "$PSScriptRoot;$env:Path"
  }
  else {
    Write-Output 'INSTALL: $PSScriptRoot already in %PATH%'
  }
  # TODO - refresh PATH in current shell
  exit 0
}

$SelfLinkOpts = ''
if ($SelfLink -eq $true) {
  $SelfLinkOpts = ',selfLink.scope(v1):label=self_link'
}

switch ($ResourceType) {
  "Compute" { 
    $outputCmd = "gcloud compute instances list --format='csv(name,zone,MACHINE_TYPE,INTERNAL_IP,EXTERNAL_IP,status,metadata.items[created-by].scope(instanceGroupManagers),id,networkInterfaces[0].subnetwork.scope(regions).segment(0):label=tmpregion,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'";
    $instructions = "[S]SH`tE[X#=`"cmd`"]ECUTE`t[C#=`"cmd`"]MD-INLINE`t[O]UTPUT-serial-log`t[T]AIL-STARTUP`t[U]PDATE-instance-template`t[^]Upload`t[v]Download`t[R]ESET`t[P]OWER-OFF`t[D]ESCRIBE`t[Q]UIT"
    $transform = 'Sort-Object -Property tmpregion,created-by,CreatedTime'
    break 
  }
  "Disks" { 
    $outputCmd = "gcloud compute disks list --format='csv(name,LOCATION:sort=1,LOCATION_SCOPE:label=lscope,SIZE_GB,TYPE,status,users[0].scope(instances),users[0].scope(projects):label=tmpUser,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime,selfLink:label=tmpSelfLink${SelfLinkOpts})'";
    $instructions = "[D]ESCRIBE`t[S]NAPSHOT`tD[E]LETE`tDE[T]ACH`t[A#=vm]TTACH`t[Q]UIT"
    # $transform='Sort-Object -Property tmpregion,created-by,CreatedTime'
    break 
  }
  "MIG" { 
    $outputCmd = "gcloud compute instance-groups managed list --format='csv(name,LOCATION,size,autoHealingPolicies[0].healthCheck.scope(healthChecks):label='autoheal_hc',creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'";
    $instructions = "[R#=#]ESIZE`t[D]ESCRIBE`t[U]PDATE`t[C]LEAR-AUTOHEALING`t[Q]UIT"
    $transform = 'Sort-Object -Property location,name'
    break 
  }
  "backend-services" {
    $outputCmd = "gcloud compute backend-services list --format='csv(name,region.scope(regions),backends[0].group.scope(instanceGroups),creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'";
    $instructions = "[P]OOL:list`t[D]ESCRIBE`t[Q]UIT"
    break 
  }
  "Configurations" {
    $outputCmd = "gcloud config configurations list --format='csv(name,is_active,ACCOUNT,PROJECT)'";
    $instructions = "[A]CTIVATE`t[C]REATE`t[Q]UIT"
    break
  }
  "Snapshots" { 
    $outputCmd = "gcloud compute snapshots list --format='csv(name,disk_size_gb,SRC_DISK,status,storageBytes,storageLocations,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'";
    $instructions = "[D]ESCRIBE`t[Q]UIT"
    # $transform='Sort-Object -Property tmpregion,created-by,CreatedTime'
    break 
  }
  "SQL" {
    $outputCmd = "gcloud sql instances list --format='csv(name:sort=1,database_version,gceZone:label='location',settings.availabilityType,settings.tier,ipAddresses[0].ipAddress,state,settings.dataDiskType:label=disk_type,settings.dataDiskSizeGb:label=disk_size,region:label=tmpregion,createTime.date(%Y-%m-%d %H:%M:%S)$SelfLinkOpts)'";
    $instructions = "[B]ACKUP`t[L]IST-BACKUPS`t[R#=backup-id]ESTORE`t[S]TART/S[T]OP`tD[E]LETE`t[Q]UIT"
    $transform = 'Sort-Object -Property name'
    break
  }
  "Storage" {
    $outputCmd = "gcloud storage buckets list --format='csv(name:sort=1,location.lower(),storageClass.lower(),timeCreated.date(%Y-%m-%d %H:%M:%S),updated.date(%Y-%m-%d %H:%M:%S),iamConfiguration.uniformBucketLevelAccess.enabled:label='uniformBLA'$SelfLinkOpts)'";
    $instructions = "[D]ESCRIBE`t[L]IST`tVE[R]SIONS`t[v]DOWNLOAD`t[^]UPLOAD`t[Q]UIT"
    $transform = 'Sort-Object -Property name'
    break
  }
  "Firewall" {
    $outputCmd = "gcloud compute firewall-rules list --format='csv(network.scope(networks):sort=1,name:sort=2,disabled,direction,priority,sourceRanges,destinationRanges,sourceTags,targetTags$SelfLinkOpts)'";
    $instructions = "[D]ESCRIBE`t[O]UT-GRIDVIEW`t[T]ARET-TAGS`t[S]OURCE-TAGS`t[Q]UIT"
    break    
  }

}

do {
  $output = $(Invoke-Expression $outputCmd)
  if ($LASTEXITCODE -ne 0) {
    $Raise_Error = "Error running gcloud command"; Throw $Raise_Error
  }

  if ($output -ne $null) {
    $instances = ConvertFrom-Csv -InputObject $output -ErrorAction SilentlyContinue
  }
  else {
    $Raise_Error = "ERROR: No $($ResourceType.ToUpper()) instances found in GCP project."; Throw $Raise_Error
  }

  if (Get-Member -InputObject $instances[0] -name "external_ip" -MemberType Properties) {
    if (($instances.external_ip | Group-Object -AsHashTable -AsString)[''].Count -eq $instances.Count) {
      $instances = $instances | Select-Object  -Property * -ExcludeProperty external_ip
    }
  }

  if ($transform) {
    $instances = Invoke-Expression "`$instances | $transform"
  }

  $outText = ($instances | Select-Object * -ExcludeProperty tmp* | ForEach-Object { $index = 1 } { $_; $index++ } | Format-Table -Property @{ Label = 'index'; Expression = { $index }; }, * -Wrap | Out-String).Replace("`r`n`r`n", "")

  if (${ReturnAs-Object} -eq $true) {
    return $instances
  }

  if ([string]::IsNullOrEmpty($Answer) -or $Answer -eq 'q') {    
    Write-Host $outText
    Write-Host "$instructions`n"
  }

  if ([string]::IsNullOrEmpty($Answer)) {
    $Answer = Read-Host 'Enter selection'
  }

  if ($Answer -eq 'q' ) {
    exit; break
  }

} while ([string]::IsNullOrEmpty($Answer))


if ($sel -eq $null) {
  # Lookup phase 0 - gcloud config configurations shortcut
  if ($ResourceType -eq 'Configurations' -and $Answer -notmatch '^\d+$' ) {
    $sel = $instances | where name -like "*$Answer*"
    $action = 'a'

    if (($sel | measure).Count -eq 0) {
      $Raise_Error = "Filter *$Answer* found no matching entries." ; Throw $Raise_Error     
    }
    elseif (($sel | measure).Count -gt 1) {
      $Raise_Error = "Filter *$Answer* matched multiple entries, pls narrow." ; Throw $Raise_Error     
    }
  }
}

if ($sel -eq $null) {
  # Lookup phase 1 - Match by index
  $Answers = Select-String -InputObject $Answer -Pattern '^([a-z\^]{1})?((\d{1,3}))?(=(.+))?$' | select -ExpandProperty Matches | select -ExpandProperty Groups | select -ExpandProperty Value

  if ($Answers -ne $null) {
    $Action = $Answers[1]
    $Item = $Answers[3]
    $Param = $Answers[5]

    if ([string]::IsNullOrEmpty($Item) -and !($ResourceType -eq 'Firewall' -and $Action -in @('o', 't', 's'))) {
      $Raise_Error = "ERROR: No item selected." ; Throw $Raise_Error     
    }
  
    $sel = $instances[$item - 1] # Selection
    Write-Host "Your selection: $sel`n"
  }
}


if ($sel -eq $null) {
  # Lookup phase 2 - Match by wildcard
  $Answers = Select-String -InputObject $Answer -Pattern '^([a-z]{1})?(:([\da-z\-\*]+))?(=(.+))?$' | select -ExpandProperty Matches | select -ExpandProperty Groups | select -ExpandProperty Value

  if ($Answers -ne $null) {
    $Action = $Answers[1]
    $Filter = $Answers[3]
    $Param = $Answers[5]

    $sel = $instances | where name -ilike "*$Filter*"

    if (($sel | measure).Count -eq 0) {
      $Raise_Error = "Filter *$Filter* found no matching entries." ; Throw $Raise_Error     
    }
    elseif (($sel | measure).Count -gt 1) {
      Write-Host "`nYour selections:"
      $sel.Name | % { "- $_" }
      Write-Host ""
      # Do nothing here but confirm with user at the next step.
    }
    else {
      Write-Host "Your selection: $sel`n"
    }
  }
}

if ($sel -eq $null) {
  $Raise_Error = "Unable to determine selection based on *$Answer*." ; Throw $Raise_Error     
}

if ($UseInternalIpSsh -eq $null) {
  # -UseInternalIpSsh switch not present, use proactive detection  
  if ((gwmi win32_computersystem).partofdomain -eq $true) {
    # Domain joined workstation, use Internal IP for SSH
    $UseInternalIpSsh = $true
  }
  else {
    # Standalone workstation, use IAP
    $UseInternalIpSsh = $false
  }
}

if ($UseInternalIpSsh) {
  $UseInternalIpCmd = "--internal-ip"
}

$selCount = $sel.Count
if ($selCount -gt 1 -and ${Show-Command} -eq $false) {
  $YesNo = Read-Host "WARNING: Execute on multiple targets? (yes/no)"
  Write-Host ""
  if (@('y', 'yes') -notcontains $YesNo) {
    exit; break
  }
}

foreach ($sel in $sel) {
  if ($selCount -gt 1 -and ${Show-Command} -eq $false) {
    Write-Host "[PS-GCLOUD] Processing: $($sel.name)...`n"
  }
  switch -regex ("${ResourceType}:${action}") {
    ".*:q$" { exit; break }
    "Compute:s?$" { $type = "hcmd"; $argListMid = "compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name)"; break }
    "Compute:u" { $type = "cmd"; $argListMid = "compute instance-groups managed update-instances --region=$($sel.zone -replace '..$') --minimal-action=replace $($sel.'created-by') --instances=$($sel.name)"; break }
    "Compute:r" { $type = "cmd"; $argListMid = "compute instances reset --zone=$($sel.zone) $($sel.name)"; break }
    "Compute:p" { $type = "cmd"; $argListMid = "compute instances stop --zone=$($sel.zone) $($sel.name)"; break }
    "Compute:o" { $type = "log"; $argListMid = "compute instances get-serial-port-output --zone=$($sel.zone) $($sel.name)"; break }
    "Compute:l" { $type = "log"; $argListMid = "compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name) --command=`"sudo journalctl -xefu google-startup-scripts.service`""; break }
    "Compute:x" { $type = "log"; $argListMid = "compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name) --command `"$($param)`""; break }
    "Compute:c" { $type = "inline"; $argListMid = "compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name) --command `"$($param)`""; break }
    "Compute:d" { $type = "inline"; $argListMid = "compute instances describe --zone=$($sel.zone) $($sel.name)"; break }
    # "Compute:t" { $type="log"; $argListMid = "beta logging tail `"resource.type=gce_instance AND resource.labels.instance_id=$($sel.id)`" --format=`"value(format('$($sel.name):{0}',json_payload.message).sub(':startup-script:',':'))`""; break }
    "Compute:t" { $type = "log"; $argListMid = "beta logging tail `"resource.type=gce_instance`" --format=`"value(format('{0}:{1}',resource.labels.instance_id,json_payload.message).sub(':startup-script:',':'))`""; break }

    'Compute:\^' { 
      $type = "cmd";
      if (!(Test-Path $param)) {
        $Raise_Error = "File or folder ``$param`` not found." ; Throw $Raise_Error     
      }
      if (Test-Path $param -PathType Container) {
        $isRecurse = '--recurse'
        $dst = '/tmp'
      }
      else {
        $isRecurse = ''
        $dst = "/tmp/$(Split-Path $param -Leaf)"
      }
      
      $argListMid = "compute scp $UseInternalIpCmd --zone=$($sel.zone) ${isRecurse} $param $($sel.name):$dst";
      Write-Output "Uploading ``$param`` to ``$dst``.`n"; break 
    }

    "Compute:v" { 
      $type = "cmd";
      # Create unique folder names as ${ComputerName}-${TargetFolderName}-${Timestamp}#
      # TODO - handle root folder
      $dst = "$($sel.name)-$(Split-Path $param -Leaf)-$(Get-Date -Format 'yyMMdd-HHmmss')"
      if ($param[-1] -eq '/') {
        # Copying a directory
        $isRecurse = '--recurse'
      }
      else {
        $isRecurse = ''
        if (!(${Show-Command})) { New-Item -ItemType Directory -Path $dst }
      }
      $argListMid = "compute scp $UseInternalIpCmd $isRecurse --zone=$($sel.zone) $($sel.name):$param $dst"; break 
    }

    "Disks:d" { $type = "inline"; $argListMid = "compute disks describe --$($sel.lscope)=$($sel.location) $($sel.name)"; break }
    "Disks:e" { $type = "inline"; $argListMid = "compute disks delete --$($sel.lscope)=$($sel.location) $($sel.name)"; break }
    "Disks:s" { $type = "cmd"; $argListMid = "compute disks snapshot --$($sel.lscope)=$($sel.location) $($sel.name) --snapshot-names=ps-gcloud-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($sel.name)"; break }
    "Disks:t" { $type = "inline"; switch ( $sel.lscope ) { region { $dscope = 'regional' }; zone { $dscope = 'zonal' }; default { $Raise_Error = "Unexpected Location Scope $($sel.lscope)." ; Throw $Raise_Error } }; $argListMid = "compute instances detach-disk `"projects/$($sel.tmpUser)`" --disk-scope=$dscope `"--disk=$($sel.tmpSelfLink)`""; break }
    "Disks:a" { $type = "inline"; switch ( $sel.lscope ) { region { $dscope = 'regional' }; zone { $dscope = 'zonal' }; default { $Raise_Error = "Unexpected Location Scope $($sel.lscope)." ; Throw $Raise_Error } }; $argListMid = "compute instances attach-disk `"$($param)`" --disk-scope=$dscope `"--disk=$($sel.tmpSelfLink)`""; break }
    "MIG:r" { $type = "cmd"; $argListMid = "compute instance-groups managed resize $($sel.name) --region=$($sel.location) --size=$($param)"; break }
    "MIG:u" { $type = "cmd"; $argListMid = "compute instance-groups managed rolling-action replace $($sel.name) --region=$($sel.location)"; break }
    "MIG:c" { $type = "cmd"; $argListMid = "compute instance-groups managed update --clear-autohealing  $($sel.name) --region=$($sel.location)"; break }
    "MIG:d" { $type = "inline"; $argListMid = "compute instance-groups managed describe $($sel.name) --region=$($sel.location)"; break }
    "Snapshots:d" { $type = "inline"; $argListMid = "compute snapshots describe $($sel.name)"; break }
    "SQL:l" { $type = "inline"; $argListMid = "sql backups list --instance=$($sel.name)"; break }
    "SQL:b" { $type = "inline"; $argListMid = "sql backups create --instance=$($sel.name)"; break }
    "SQL:s" { $type = "cmd"; $argListMid = "sql instances patch $($sel.name) --activation-policy=ALWAYS "; break }
    "SQL:t" { $type = "cmd"; $argListMid = "sql instances patch $($sel.name) --activation-policy=NEVER "; break }
    "SQL:r" { $type = "show-command"; $argListMid = "sql backups restore --restore-instance=$($sel.name)  $param"; ${Show-Command} = $true; break }
    "SQL:e" { $type = "inline"; $argListMid = "sql instances delete $($sel.name) "; break }
    "Storage:d" { $type = "inline"; $argListMid = "storage buckets describe gs://$($sel.name)"; break }
    "Storage:l" { $type = "log"; $argListMid = "storage ls -r gs://$($sel.name)"; break }
    "Storage:r" { $type = "log"; $argListMid = "storage ls -r --all-versions gs://$($sel.name)"; break }
    "Storage:v" {
      $type = "cmd";
      if (!$Param) {
        Write-Debug "No param specified, using root directory"
        $src = "gs://$($sel.name)/*"
        $pathName = 'root'
      }
      elseif ($Param[-1] -in @('/', '\')) {
        Write-Debug "Downloading a folder"
        $src = "gs://$($sel.name)/${param}*"
        $pathName = Split-Path $Param -Leaf
      }
      else {
        Write-Debug "Downloading a file"
        $src = "gs://$($sel.name)/${param}"
        $pathName = Split-Path $Param -Leaf
      }
      # Create unique folder names as ${ComputerName}-${TargetFolderName}-${Timestamp}
      $dst = "gs--$($sel.name)-${pathName}-$(Get-Date -Format 'yyMMdd-HHmmss')" -replace '\*', '_'
      if (!(${Show-Command})) { New-Item -ItemType Directory -Path $dst }
      $argListMid = "storage cp -r $src ./$dst";
    }

    "Storage:\^" {
      $type = "cmd";
      $src = $param
      $dst = $sel.name
      if (!(Test-Path $src)) {
        $Raise_Error = "File or folder ``$src`` not found." ; Throw $Raise_Error     
      }
      
      $argListMid = "storage cp -r $src gs://$dst";
      Write-Output "Uploading ``$src`` to ``$dst``.`n"; break 
    }
    "backend-services:p?$" { $type = "inline"; $argListMid = "compute backend-services get-health $($sel.name) --region=$($sel.region) --format='table(status.healthStatus.instance.scope(instances),status.healthStatus.instance.scope(zones).segment(0):label='zone',status.healthStatus.ipAddress,status.healthStatus.healthState)' --flatten='status.healthStatus'"; break }
    "backend-services:d$" { $type = "inline"; $argListMid = "compute backend-services describe $($sel.name) --region=$($sel.region) --format=yaml"; break }
    "Configurations:a?$" { $type = "inline"; $argListMid = "config configurations activate $($sel.name)"; break }
    "Configurations:c" { $type = "inline"; $argListMid = "config configurations create $($sel.name)"; break }
    "Firewall:o" { $instances | Out-GridView; return }
    "Firewall:t" {
      $of = gcloud compute firewall-rules list --format=json | ConvertFrom-Json
      # $tags = @{}
      $tags = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
      foreach ($f in $of) {
        foreach ($t in $f.targetTags) {
          if ($tags.ContainsKey($t)) {
            $tags[$t].Firewall_rules += $f.name
            $tags[$t].Count += 1
          }
          else {
            $tag = New-Object psobject
            $tag | Add-Member -MemberType NoteProperty -Name Key -Value $t
            $tag | Add-Member -MemberType NoteProperty -Name Count -Value 1
            $tag | Add-Member -MemberType NoteProperty -Name Firewall_rules -Value @([System.Collections.Generic.List[System.Object]]$f.name)
            $tags.Add($t, $tag)
          }
        }
      }
      $tags.GetEnumerator() | Select-Object -ExpandProperty Value | Sort-Object -Property Key | Out-GridView
      return
    }
    "Firewall:s" {
      $of = gcloud compute firewall-rules list --format=json | ConvertFrom-Json
      $tags = @{}
      foreach ($f in $of) {
        foreach ($t in $f.sourceTags) {
          if ($tags.ContainsKey($t)) {
            $tags[$t].Firewall_rules += $f.name
            $tags[$t].Count += 1
          }
          else {
            $tag = New-Object psobject
            $tag | Add-Member -MemberType NoteProperty -Name Key -Value $t
            $tag | Add-Member -MemberType NoteProperty -Name Count -Value 1
            $tag | Add-Member -MemberType NoteProperty -Name Firewall_rules -Value @([System.Collections.Generic.List[System.Object]]$f.name)
            $tags.Add($t, $tag)
          }
        }
      }
      $tags | Out-GridView
      return
    }
    default { $Raise_Error = "No action defined for ``${ResourceType}:${action}``" ; Throw $Raise_Error }
  }

  # ConEmu detection
  if (Get-Command -ErrorAction Ignore -Type Application conemu) {
    Write-Debug "ConEmu found in path."
    $ConEmuCmd = "conemu"
  }
  else {
    Write-Debug "ConEmu is running, we can get the path from there."
    $ConEmuCmd = (Get-Process conemu -ErrorAction Ignore | Select-Object -First 1 ).Path
  }

  # YQ detection
  if (Get-Command -ErrorAction Ignore -Type Application yq) {
    Write-Debug "YQ found in path."
    $YQCmd = "yq"
  }
  else {
    $YQCmd = $null
  }

  if (${Show-Command}) {
    Write-Output "COMMAND: gcloud $argListMid`n"
    return
  }

  if ($type -eq "log" -and $ConEmuCmd) {
    $type = "logconemu"
  }
  if ($action -eq "d" -and $YQCmd) {
    $type = "inlineyq"
  }

  # Default Exec Style
  $ExecStyle = New-Object -TypeName PsObject -Property @{
    Shell              = "cmd";
    ShellParams        = "/c";
    WindowStyle        = "Normal";
    SleepCmd           = "& timeout /t 60"
    AdditionalSwitches = @{}
  }

  switch ($type) {
    "cmd" {
      # Already handled in default 
    }
    "hcmd" { 
      $ExecStyle.AdditionalSwitches = @{WindowStyle = "Minimized" }
    }
    "inline" { 
      $ExecStyle.shellParams = "/c"; 
      $ExecStyle.SleepCmd = "";
      $ExecStyle.AdditionalSwitches = @{NoNewWindow = $true; Wait = $true }
    }
    "inlineyq" { 
      $ExecStyle.shellParams = "/c"; 
      $ExecStyle.SleepCmd = "| yq";
      $ExecStyle.AdditionalSwitches = @{NoNewWindow = $true; Wait = $true }
    }
    "log" {
      $ExecStyle.AdditionalSwitches = @{WindowStyle = "Maximized" };
      $ExecStyle.SleepCmd = "& pause"
    }
    "logconemu" {
      $ExecStyle.shell = $ConEmuCmd;
      $ExecStyle.shellParams = "-run";
      $ExecStyle.SleepCmd = "& pause"
      $ExecStyle.AdditionalSwitches = @{WindowStyle = "Maximized" };
    }
    default { $Raise_Error = "Unexpected exec type: $type" ; Throw $Raise_Error }
  }

  $argList = "$($ExecStyle.shellParams) gcloud $argListMid $($ExecStyle.SleepCmd)"

  $AdditionalSwitches = $ExecStyle.AdditionalSwitches

  Write-Debug "ExecStyle: $ExecStyle"
  Write-Debug "AdditionalSwitches: $($AdditionalSwitches | Out-String)"

  Start-Process $($ExecStyle.shell) -ArgumentList "$argList " @AdditionalSwitches

  if ($type -eq "inline") {
    Write-Host ''
  }
}
