<#PSScriptInfo
.VERSION      2023.01.28
.AUTHOR       Levente Rog
.COPYRIGHT    (c) 2023 Levente Rog
.LICENSEURI   https://github.com/levid0s/PS-Gcloud/blob/master/LICENSE.md
.PROJECTURI   https://github.com/levid0s/PS-Gcloud/
#>

<#
  .SYNOPSIS
    PowerShell wrapper for Gcloud CLI, v2023.01.28

  .DESCRIPTION
    PowerShell wrapper for Gcloud CLI. Handy because of the autocomplete, sensible defaults, very brief commands, wildcard matching, targetting multiple resources, and more.

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
    .\PS-Gcloud.ps1 ^1                          # Select a file using file picker to upload to VM with index 1
    .\PS-Gcloud.ps1 ^1=?                        # Select a folder using folder picker to upload to VM with index 1 to /tmp
    .\PS-Gcloud.ps1 ^1=c:\windows               # Upload the c:\windows directory to /tmp/windows on VM1
    .\PS-Gcloud.ps1 ^:*=hello.txt               # Upload `./hello.txt` to all VMs in the project
    .\PS-Gcloud.ps1 ^:rhel=?                    # Select a folder using picker UI to upload to the VMs named *rhel*
    .\PS-Gcloud.ps1 v1=/etc/passwd              # Download /etc/passwd file from VM1 to ./{hostname}-passwd-{timestamp} directory
    .\PS-Gcloud.ps1 v:web=/var/log              # Download /var/log folder from *web* VMs
    .\PS-Gcloud.ps1 -Configurations q           # List configurations and quit
    .\PS-Gcloud.ps1 -ResourceType Disks         # Do stuff with disks like Describe, Snapshot, Delete, Detach, Attach
    .\PS-Gcloud.ps1 -Disks                      # Shorthand switch for -ResourceType Disks. There's a shorthand switch for each ResourceType
    .\PS-Gcloud.ps1 -Disks a4="consumer-testvm" # Attach disk 4 to the VM named `consumer-testvm`
    .\PS-Gcloud.ps1 -Install                    # Add the location of the script in the user %PATH%
    $vms = .\PS-Gcloud.ps1 -ReturnAs-Object     # Return the list of VMs as object. It is not the entire GCP resource though, only has the details from the table.
    .\PS-Gcloud.ps1 -SelfLink                   # Add the relative self_link column to the selection table

    .\PS-Gcloud.ps1 -Disks a1=consumer-testvm -Show-Command   # Show the equivalent gcloud command instead of executing it

    .LINK
    https://github.com/levid0s/PS-Gcloud
#>

param(
  [Parameter()][ValidateSet('Backend-Services', 'Compute', 'Configurations', 'Disks', 'Firewall', 'MIG', 'Snapshots', 'SQL', 'Storage')][string]$ResourceType,
  [nullable[bool]]$UseInternalIpSsh,
  [Parameter(Position = 0)][string]$Answer,
  [Switch]$Install,
  [Switch]${Show-Command},
  [Switch]${ReturnAs-Object}, # TBC
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
  return
}

if ($HelpFull) {
  $MyScript = $MyInvocation.MyCommand.Source
  Get-Help $MyScript -Full
  return
}

if ($Install -eq $true -and ![string]::IsNullOrEmpty($PSScriptRoot)) {
  Install-Script
  return
}

$ResourceTypes = @('Backend-Services', 'Compute', 'Configurations', 'Disks', 'Firewall', 'MIG', 'Snapshots', 'SQL', 'Storage')
$SelfLink = $SelfLink -or $Uri

# Shorthand ResourceType switch validation
if ([string]::IsNullOrEmpty($ResourceType)) {
  foreach ($rt in $ResourceTypes) {
    # Dynamically check if the switches are present
    $rtval = Invoke-Expression "`${$rt}"
    if ($rtval -eq $true) {
      $ResourceType = $rt
      break
    }
  }
  if ([string]::IsNullOrEmpty($ResourceType)) {
    $ResourceType = 'Compute'
  }
}

. $PSScriptRoot/_PSGcloudHelper.ps1

$LoadOptions = Get-LoadOptions -ResourceType $ResourceType
$SelOptions = Get-SelOptions -ResourceType $ResourceType

# Prompt the user to enter the answer on the screen, returns the answer and the full list of instances
$Selection = Show-Menu -LoadOptions $LoadOptions -SelOptions $SelOptions -Answer $Answer -SelfLink ${SelfLink}

# Match the answer to the list of instances; do regex magic
$Selections = Parse-Answer -ResourceType $ResourceType -Instances $Selection.instances -Answer $Selection.answer

# Filter through the SelOptions list to get the right action
$SelAction = Find-SelAction -ResourceType $ResourceType -SelOptions $SelOptions -Selections $Selections

if ($SelAction.NoSelNeeded) {
  $Selections.Selections = @("Hello")
}
DisplaySelectionsAndConfirm -Answers $Selections -Show-Command ${Show-Command}

# Execute the SelAction on the list of selections
Invoke-Selections -Selections $Selections -SelAction $SelAction -Show-Command ${Show-Command} -Instances $Selection.instances