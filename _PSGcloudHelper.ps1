function Get-LoadOptions {
  param(
    [string]$ResourceType
  )

  $LoadOptions = @()

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Compute'
    LoadCmd   = 'gcloud compute instances list --format=''csv(name,zone,MACHINE_TYPE,INTERNAL_IP,EXTERNAL_IP,status,metadata.items[created-by].scope(instanceGroupManagers),id,networkInterfaces[0].subnetwork.scope(regions).segment(0):label=tmpregion,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'''
    Transform = 'Sort-Object -Property tmpregion, created-by, CreatedTime'
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Disks'
    LoadCmd   = 'gcloud compute disks list --format=''csv(name,LOCATION:sort=1,LOCATION_SCOPE:label=lscope,SIZE_GB,TYPE,status,users[0].scope(instances),users[0].scope(projects):label=tmpUser,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime,selfLink:label=tmpSelfLink${SelfLinkOpts})'''
    Transform = $null
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'MIG'
    LoadCmd   = 'gcloud compute instance-groups managed list --format=''csv(name,LOCATION,size,autoHealingPolicies[0].healthCheck.scope(healthChecks):label=''autoheal_hc'',creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'''
    Transform = $null
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Backend-Services'
    LoadCmd   = 'gcloud compute backend-services list --format=''csv(name,region.scope(regions),backends[0].group.scope(instanceGroups),creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'''
    Transform = $null
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Configurations'
    LoadCmd   = 'gcloud config configurations list --format=''csv(name,is_active,ACCOUNT,PROJECT)'''
    Transform = $null
  }  

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Snapshots'
    LoadCmd   = 'gcloud compute snapshots list --format=''csv(name,disk_size_gb,SRC_DISK,status,storageBytes,storageLocations,creationTimestamp.date(%Y-%m-%d %H:%M:%S):label=CreatedTime$SelfLinkOpts)'''
    Transform = $null
  }  

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'SQL'
    LoadCmd   = 'gcloud sql instances list --format=''csv(name:sort=1,database_version,gceZone:label=''location'',settings.availabilityType,settings.tier,ipAddresses[0].ipAddress,state,settings.dataDiskType:label=disk_type,settings.dataDiskSizeGb:label=disk_size,region:label=tmpregion,createTime.date(%Y-%m-%d %H:%M:%S)$SelfLinkOpts)'''
    Transform = $null
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Storage'
    LoadCmd   = 'gcloud storage buckets list --format=''csv(name:sort=1,location.lower(),storageClass.lower(),timeCreated.date(%Y-%m-%d %H:%M:%S),updated.date(%Y-%m-%d %H:%M:%S),iamConfiguration.uniformBucketLevelAccess.enabled:label=''uniformBLA''$SelfLinkOpts)'''
    Transform = $null
  }

  $LoadOptions += New-Object -TypeName PsObject -Property @{
    Category  = 'Firewall'
    LoadCmd   = 'gcloud compute firewall-rules list --format=''csv(network.scope(networks):sort=1,name:sort=2,disabled,direction,priority,sourceRanges,destinationRanges,sourceTags,targetTags,logConfig.enable.lower():label=''logging''$SelfLinkOpts)'''
    Transform = $null
  }

  $o = $LoadOptions | Where-Object { $ResourceType -match $_.Category } 
  return $o
}

function Get-SelOptions {
  param(
    [string]$ResourceType
  )
  
  $SelOptions = @()

  ###
  ###  Quit
  ###  

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = '.*'
    HelpItem     = '[Q]UIT'
    MenuIndex    = 1000
    Regex        = '.*:q$'
    ShellArgsMid = ''
    ShellType    = 'quit'
  }

  ###
  ###  Backend-Services
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Backend-Services'
    HelpItem     = '[P]OOL-LIST'
    Default      = $true
    MenuIndex    = 1
    Hotkey       = 'p'
    ShellArgsMid = 'compute backend-services get-health $($sel.name) --region=$($sel.region) --format=''table(status.healthStatus.instance.scope(instances),status.healthStatus.instance.scope(zones).segment(0):label=''zone'',status.healthStatus.ipAddress,status.healthStatus.healthState)'' --flatten=''status.healthStatus'''
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Backend-Services'
    HelpItem     = '[D]ESCRIBE'
    MenuIndex    = 2
    Hotkey       = 'd'
    ShellArgsMid = 'compute backend-services get-health $($sel.name) --region=$($sel.region) --format=''table(status.healthStatus.instance.scope(instances),status.healthStatus.instance.scope(zones).segment(0):label=''zone'',status.healthStatus.ipAddress,status.healthStatus.healthState)'' --flatten=''status.healthStatus'''
    ShellType    = 'inlineyq'
  }

  ###
  ###  Compute
  ###  

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    Default      = $true
    MenuIndex    = 1
    HelpItem     = '[S]SH'
    Hotkey       = 's'
    ShellArgsMid = 'compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'hcmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    MenuIndex    = 2
    ShellArgsMid = 'compute instances describe --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[C#=cmd]-INLINE'
    MenuIndex    = 3
    Hotkey       = 'c'
    ShellArgsMid = 'compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name) --command "$param"'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = 'E[X#=cmd]ECUTE'
    MenuIndex    = 4
    Hotkey       = 'x'
    ShellArgsMid = 'compute ssh $UseInternalIpCmd --zone=$($sel.zone) $($sel.name) --command "$param"'
    ShellType    = 'log'
  }
  
  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[O]UTPUT-seral-log'
    MenuIndex    = 5
    Hotkey       = 'o'
    ShellArgsMid = 'compute instances get-serial-port-output --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'log'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[^#=c:/file/to/upload.txt]'
    Hotkey       = '^'
    MenuIndex    = 6
    ShellArgsMid = 'compute scp $UseInternalIpCmd --zone=$($sel.zone) $Script:RecurseCmd $script:Param $($sel.name):${Script:dst}'
    ShellType    = 'cmd'
    TaskPrep     = {
      if (!$Script:Param) {
        if ($Param -eq '?' -or $Param -eq '*') {
          $Script:Param = Get-FolderPicker($PWD)
          Write-Verbose "Selected folder with picker: $Script:Param"          
        }
        elseif ($Param) {
          $Script:Param = $Param
        }
        else {
          $Script:Param = Get-FilePicker($PWD)
          Write-Verbose "Selected file with picker: $Script:Param"
        }      
      }
      Write-Debug "Param: $Param, ScriptParam: $Script:Param"
      if (!(Test-Path $Script:param)) {
        $Raise_Error = "File or folder ``$param`` not found." ; Throw $Raise_Error     
      }
      $Script:dst = '/tmp'
      if (Test-Path $Script:param -PathType Container) {
        $Script:RecurseCmd = '--recurse'
      }
      else {
        $Script:RecurseCmd = ''
        # $dst = "/tmp/$(Split-Path $Script:param -Leaf)"
      }
    }
    TaskPost     = {
      Write-Output "Uploading ``$Script:param`` to ``$dst``.`n"
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[v#=/path/to/download]DOWNLOAD'
    Hotkey       = 'v'
    MenuIndex    = 7
    ShellArgsMid = 'compute scp $UseInternalIpCmd --recurse --zone=$($sel.zone) $($sel.name):$param $TaskPrep'
    ShellType    = 'cmd'
    TaskPrep     = {
      $dstName = "$($sel.name)--$(Get-Date -Format 'yyyyMMdd-HHmmss')--$(Split-Path $param -Leaf)"
      $Dst = New-Item -ItemType Directory -Path $dstName | Select-Object -ExpandProperty FullName
      if (${Show-Command}) {
        Return
      }
      Return $Dst
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[P]OWER-OFF'
    Hotkey       = 'p'
    MenuIndex    = 8
    ShellArgsMid = 'compute instances stop --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'ncmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[R]ESET'
    Hotkey       = 'r'
    MenuIndex    = 9
    ShellArgsMid = 'compute instances reset --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'ncmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[U]PDATE'
    Hotkey       = 'u'
    MenuIndex    = 10
    ShellArgsMid = 'compute instance-groups managed update-instances --region=$($sel.zone -replace ''..$'') --minimal-action=replace $($sel.''created-by'') --instances=$($sel.name)' # Is this right?
    ShellType    = 'ncmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[L]OG'
    MenuHidden   = $true
    MenuIndex    = 20
    Hotkey       = 'l'
    ShellArgsMid = 'compute instances get-serial-port-output --zone=$($sel.zone) $($sel.name)'
    ShellType    = 'log'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Compute'
    HelpItem     = '[T]AIL-STARTUP'
    Hotkey       = 't'
    MenuIndex    = 20
    MenuHidden   = $true
    ShellArgsMid = 'beta logging tail `"resource.type=gce_instance`" --format=`"value(format(''{ 0 }: { 1 }'',resource.labels.instance_id,json_payload.message).sub('':startup-script:'','':''))`"'
    ShellType    = 'log'
  }


  ###
  ###  Configurations
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Configurations'
    Default      = $true
    HelpItem     = '[A]CTIVATE'
    Hotkey       = 'a'
    MenuIndex    = 1
    ShellArgsMid = 'config configurations activate $($sel.name)'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Configurations'
    HelpItem     = '[C]REATE'
    Hotkey       = 'c'
    MenuIndex    = 2
    NoSelNeeded  = $true
    ShellArgsMid = 'config configurations create $param'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Configurations'
    HelpItem     = 'LIST-[P]ROJECTS'
    Hotkey       = 'p'
    MenuIndex    = 3
    NoSelNeeded  = $true
    ShellArgsMid = 'projects list'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Configurations'
    Confirm      = $true
    HelpItem     = 'D[E]LETE'
    Hotkey       = 'e'
    MenuIndex    = 5
    ShellArgsMid = 'config configurations delete $($sel.name)'
    ShellType    = 'inline'
  }

  ###
  ###  Disks
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Disks'
    Default      = $true
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    ShellArgsMid = 'compute disks describe --$($sel.lscope)=$($sel.location) $($sel.name)'
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Disks'
    Confirm      = $true
    HelpItem     = 'D[E]LETE'
    Hotkey       = 'e'
    ShellArgsMid = 'compute disks describe --$($sel.lscope)=$($sel.location) $($sel.name)'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Disks'
    HelpItem     = '[S]NAPSHOT'
    Hotkey       = 's'
    ShellArgsMid = 'compute disks snapshot --$($sel.lscope)=$($sel.location) $($sel.name) --snapshot-names=ps-gcloud-$(Get-Date -Format ''yyyyMMdd-HHmmss'')-$($sel.name)'
    ShellType    = 'cmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Disks'
    HelpItem     = 'DE[T]ACH'
    Hotkey       = 't'
    ShellArgsMid = 'compute instances detach-disk `"projects/$($sel.tmpUser)`" --disk-scope=$dscope `"--disk=$($sel.tmpSelfLink)`"'
    ShellType    = 'inline'
    TaskPrep     = {
      switch ( $sel.lscope ) { 
        region { $dscope = 'regional' }; 
        zone { $dscope = 'zonal' };
        default { $Raise_Error = "Unexpected Location Scope $($sel.lscope)." ; Throw $Raise_Error } 
      }
      return @{ dscope = $dscope }
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Disks'
    HelpItem     = '[A]TTACH'
    Hotkey       = 'a'
    ShellArgsMid = 'compute instances attach-disk `"$($param)`" --disk-scope=$dscope `"--disk=$($sel.tmpSelfLink)`"'
    ShellType    = 'inline'
    TaskPrep     = {
      switch ( $sel.lscope ) { 
        region { $dscope = 'regional' }; 
        zone { $dscope = 'zonal' };
        default { $Raise_Error = "Unexpected Location Scope $($sel.lscope)." ; Throw $Raise_Error } 
      }
      return @{ dscope = $dscope }
    }
  }

  ###
  ###  Firewall
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Firewall'
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    ShellArgsMid = 'compute firewall-rules describe $($sel.name) --format=''yaml'''
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Firewall'
    HelpItem     = '[O]UT-GRIDVIEW'
    Hotkey       = 'o'
    NoSelNeeded  = $true
    ShellArgsMid = ''
    ShellType    = 'out-gridview'
    TaskPrep     = {
      $global:FirewallRules = $Instances
      $global:FirewallRulesSelected | Out-GridView -PassThru
      Write-Information -InformationAction Continue "Data saved in vars: `$FirewallRules, `$FirewallRulesSelected"
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Firewall'
    HelpItem     = '[T]ARGET-TAGS'
    Hotkey       = 't'
    NoSelNeeded  = $true
    ShellArgsMid = ''
    ShellType    = 'out-gridview'
    TaskPrep     = {
      $of = gcloud compute firewall-rules list --format=json | ConvertFrom-Json
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
            $tag | Add-Member -MemberType NoteProperty -Name Network -Value ($f.network -split '/' | Select-Object -Last 1)
            $tag | Add-Member -MemberType NoteProperty -Name Firewall_rules -Value @([System.Collections.Generic.List[System.Object]]$f.name)
            $tags.Add($t, $tag)
          }
        }
      }

      $global:FirewallTags = $tags.GetEnumerator() | Select-Object -ExpandProperty Value | Sort-Object -Property Key
      $global:FirewallTagsSelected = $FirewallTags | Out-GridView -PassThru
      Write-Information -InformationAction Continue "Data saved in vars: `$FirewallTags, `$FirewallTagsSelected"
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Firewall'
    HelpItem     = '[S]OURCE-TAGS'
    Hotkey       = 's'
    NoSelNeeded  = $true
    ShellArgsMid = ''
    ShellType    = 'out-gridview'
    TaskPrep     = {
      $of = gcloud compute firewall-rules list --format=json | ConvertFrom-Json
      $tags = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
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
            $tag | Add-Member -MemberType NoteProperty -Name Network -Value ($f.network -split '/' | Select-Object -Last 1)
            $tag | Add-Member -MemberType NoteProperty -Name Firewall_rules -Value @([System.Collections.Generic.List[System.Object]]$f.name)
            $tags.Add($t, $tag)
          }
        }
      }
      $global:FirewallTags = $tags.GetEnumerator() | Select-Object -ExpandProperty Value | Sort-Object -Property Key
      $global:FirewallTagsSelected = $FirewallTags | Out-GridView -PassThru
      Write-Information -InformationAction Continue "Data saved in vars: `$FirewallTags, `$FirewallTagsSelected"
    }
  }


  ###
  ###  MIG
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'MIG'
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    MenuIndex    = 1
    ShellArgsMid = 'compute instance-groups managed describe $($sel.name) --region=$($sel.location)'
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'MIG'
    HelpItem     = '[R#=#]ESIZE'
    Hotkey       = 'r'
    MenuIndex    = 2
    ShellArgsMid = 'compute instance-groups managed resize $($sel.name) --region=$($sel.location) --size=$($param)'
    ShellType    = 'cmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'MIG'
    HelpItem     = '[U]PDATE'
    Hotkey       = 'u'
    MenuIndex    = 3
    ShellArgsMid = 'compute instance-groups managed rolling-action replace $($sel.name) --region=$($sel.location)'
    ShellType    = 'cmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'MIG'
    HelpItem     = '[C]LEAR-AUTOHEAL'
    Hotkey       = 'c'
    MenuIndex    = 4
    ShellArgsMid = 'compute instance-groups managed update --clear-autohealing  $($sel.name) --region=$($sel.location)'
    ShellType    = 'cmd'
  }

  ###
  ###  Snapshots
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Snapshots'
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    ShellArgsMid = 'compute snapshots describe $($sel.name)'
    ShellType    = 'inlineyq'
  }

  ###
  ###  SQL
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    ShellArgsMid = 'sql instances describe $($sel.name)'
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = '[L]IST-BACKUPS'
    Hotkey       = 'l'
    ShellArgsMid = 'sql backups list --instance=$($sel.name)'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = '[B]ACKUP'
    Hotkey       = 'b'
    ShellArgsMid = 'sql backups create --instance=$($sel.name)'
    ShellType    = 'inline'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = '[R#=backup-id]ESTORE'
    Hotkey       = 'r'
    ShellArgsMid = 'sql backups restore --restore-instance=$($sel.name)  $param'
    ShellType    = 'show-command'
  }  

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = '[S]TART'
    Hotkey       = 's'
    ShellArgsMid = 'sql instances patch $($sel.name) --activation-policy=ALWAYS'
    ShellType    = 'cmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    HelpItem     = 'S[T]OP'
    Hotkey       = 't'
    ShellArgsMid = 'sql instances patch $($sel.name) --activation-policy=NEVER '
    ShellType    = 'cmd'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'SQL'
    Confirm      = $true
    HelpItem     = 'D[E]LETE'
    Hotkey       = 'e'
    ShellArgsMid = 'sql instances delete $($sel.name)'
    ShellType    = 'inline'
  }

  ###
  ###  Storage
  ###

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Storage'
    Default      = $true
    MenuIndex    = 1
    HelpItem     = '[D]ESCRIBE'
    Hotkey       = 'd'
    ShellArgsMid = 'storage buckets describe gs://$($sel.name)'
    ShellType    = 'inlineyq'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Storage'
    HelpItem     = '[L]IST'
    MenuIndex    = 2
    Hotkey       = 'l'
    ShellArgsMid = 'storage ls -r gs://$($sel.name)'
    ShellType    = 'log'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Storage'
    HelpItem     = 'VE[R]SIONS'
    MenuIndex    = 3
    Hotkey       = 'r'
    ShellArgsMid = 'storage ls -r --all-versions gs://$($sel.name)'
    ShellType    = 'log'
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Storage'  
    HelpItem     = '[v]DOWNLOAD'
    Hotkey       = 'v'
    MenuIndex    = 4
    ShellArgsMid = 'storage cp -r $($TaskPrep.src) ./$($TaskPrep.dst)'
    ShellType    = 'cmd'
    TaskPrep     = {
      if (!$Param) {
        Write-Debug 'No param specified, using root directory'
        
        $src = "gs://$($sel.name)/*".clone()
        $pathName = 'root'
      }
      elseif ($Param[-1] -in @('/', '\')) {
        Write-Debug 'Downloading a folder'
        $src = "gs://$($sel.name)/${param}*".clone()
        $pathName = Split-Path $Param -Leaf
      }
      else {
        Write-Debug 'Downloading a file'
        $src = "gs://$($sel.name)/${param}".clone()
        $pathName = Split-Path $Param -Leaf
      }
      # Create unique folder names as ${ComputerName}-${TargetFolderName}-${Timestamp}
      $dst = "gs--$($sel.name)-${pathName}-$(Get-Date -Format 'yyMMdd-HHmmss')".clone() -replace '\*', '_'
      $dst1 = $dst.clone()
      if (!(${Show-Command})) { New-Item -ItemType Directory -Path $dst1 | Out-Null }
      return @{ src = $src ; dst = $dst }
    }
  }

  $SelOptions += New-Object -TypeName PsObject -Property @{
    Category     = 'Storage'  
    HelpItem     = '[^]UPLOAD'
    Hotkey       = '^'
    MenuIndex    = 5
    ShellArgsMid = 'storage cp -r $($TaskPrep.src) gs://$($TaskPrep.dst)'
    ShellType    = 'cmd'
    TaskPrep     = {
      $src = $Param
      $dst = $sel.name
      if (!(Test-Path $src)) {
        $Raise_Error = "File or folder ``$src`` not found." ; Throw $Raise_Error     
      }
      return @{ src = $src ; dst = $dst }  
    }
  }


  $o = $SelOptions | Where-Object { $ResourceType -match $_.Category } 

  foreach ($i in 1..(($o.Count) - 1)) {
    if ($null -eq $o[$i].MenuIndex) {
      Add-Member -InputObject $o[$i] -NotePropertyName MenuIndex -NotePropertyValue 500
    }
  }

  return $o
}


function Show-Menu {
  param(
    $LoadOptions,
    $SelOptions,
    $Answer,
    ${SelfLink}
  )

  $SelfLinkOpts = ''
  if ($SelfLink -eq $true) {
    $SelfLinkOpts = ',selfLink.scope(v1):label=self_link'
  }

  $instructions = ($SelOptions | Where-Object MenuHidden -NE $true | Sort-Object -Property MenuIndex | Select-Object -ExpandProperty HelpItem) -join '   '

  do {
    $LoadOptions.LoadCmd = $ExecutionContext.InvokeCommand.ExpandString($LoadOptions.LoadCmd)
    $output = $(Invoke-Expression $LoadOptions.LoadCmd)
    if ($LASTEXITCODE -ne 0) {
      $Raise_Error = 'Error running gcloud command'; Throw $Raise_Error
    }
  
    if ($null -ne $output) {
      $instances = ConvertFrom-Csv -InputObject $output -ErrorAction SilentlyContinue
    }
    else {
      $Raise_Error = "ERROR: No $($ResourceType.ToUpper()) instances found in GCP project."; Throw $Raise_Error
    }
  
    if (Get-Member -InputObject $instances[0] -Name 'external_ip' -MemberType Properties) {
      if (($instances.external_ip | Group-Object -AsHashTable -AsString)[''].Count -eq $instances.Count) {
        $instances = $instances | Select-Object -Property * -ExcludeProperty external_ip
      }
    }
  
    if ($LoadOptions.Transform) {
      $instances = Invoke-Expression "`$instances | $($LoadOptions.Transform)"
    }
  
    $outText = ($instances | Select-Object * -ExcludeProperty tmp* | ForEach-Object { $index = 1 } { $_; $index++ } | Format-Table -Property @{ Label = 'index'; Expression = { $index }; }, * -Wrap | Out-String).Replace("`r`n`r`n", '')
  
    if (${ReturnAs-Object} -eq $true) {
      # TBC
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

  return @{
    instances = $instances
    answer    = $Answer
  }
}


function ConfigurationsActivateWildcard {
  param(
    [array]$Menu,
    [string]$Wildcard
  )

  Write-Debug '[ConfigurationsActivateWildcard]: Start'
  # Search by configuration name or project id
  [array]$sel = $Menu | Where-Object { ($_.name -like "*$Wildcard*") -or ($_.project -like "*$Wildcard*") }
  if ($sel.Count -eq 1) {
    return @{ Selections = $sel }
  }
  if ($sel.Count -gt 1) {
    $Raise_Error = "Filter *$Wildcard* found more than one matching configurations, please narrow." ; Throw $Raise_Error
  }
  
  # Search by project name
  [array]$projects = gcloud projects list --format='json' --filter="name:*$Wildcard*" | ConvertFrom-Json
  if ($projects.Count -eq 0) {
    $Raise_Error = "Filter *$Wildcard* found no matching projects." ; Throw $Raise_Error
  }
  if ($projects.Count -gt 1) {
    $Raise_Error = "Filter *$Wildcard* found more than one matching projects, please narrow." ; Throw $Raise_Error
  }

  Selections = [array]$Menu | Where-Object project -EQ $projects.projectId

  Write-Debug "[ConfigurationsActivateWildcard]: Finished, project found: $Selections."
  return @{
    Action     = 'a'
    SelIndex   = $null
    Param      = $null
    Selections = $Selections
    SelCount   = 1
  }

  $sel = $Menu | Where-Object project -EQ $projects.projectId
  return $sel
}
function ExtractAnswersByIndex {
  param(
    [string]$Answer,
    [array]$Menu
  )
  Write-Debug "[ExtractAnswersByIndex] Answer= ``$Answer``"
  [array]$Answers = Select-String -InputObject $Answer -Pattern '^([a-z\^]{1})?((\d{1,3}))?(=(.+))?$' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value

  if ($null -eq $Answers) {
    return $null
  }

  if ($Answers[3]) {
    [array]$Selections = $Menu[$Answers[3] - 1] 
  }

  return @{
    Action     = $Answers[1]
    SelIndex   = $Answers[3]
    Param      = $Answers[5]
    Selections = $Selections
    SelCount   = $Selections.Count
  }
}

function ExtractAnswersByWildcard {
  param(
    [string]$Answer,
    [array]$Menu
  )
  Write-Debug "[ExtractAnswersByWildcard] Answer= ``$Answer``"
  [array]$Answers = Select-String -InputObject $Answer -Pattern '^([a-z\^]{1})?(:([\da-z\-\*]+))?(=(.+))?$' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value

  if ($null -eq $Answers) {
    Write-Debug "[ExtractAnswersByWildcard] Pattern not matched ``$Answer``"
    return $null
  }

  $Filter = $Answers[3]
  [array]$Selections = $Menu | Where-Object name -ilike "*$Filter*"

  return @{
    Action     = $Answers[1]
    SelIndex   = $null
    Param      = $Answers[5]
    Selections = $Selections
    SelCount   = $Selections.Count
  }
}

function DetectUseInternalIpSsh {
  param(
    $Switch
  )

  if ($Switch -eq $null) {
    # -UseInternalIpSsh switch not present, use proactive detection  
    # Domain joined workstation -> use Internal IP for SSH
    # Standalone workstation -> use IAP
    $Switch = (Get-WmiObject win32_computersystem).partofdomain 
  }

  if ($Switch -eq $true) {
    $Cmd = '--internal-ip'
  }
  else {
    $Cmd = ''
  }

  return @{
    Switch = $Switch
    Cmd    = $Cmd
  }
}

function DisplaySelectionsAndConfirm {
  param(
    [array]$Answers,
    [bool]${Show-Command}
  )

  if (${Show-Command} -eq $true) {
    return
  }
  if ($Answers.SelCount -lt 1) {
    return
  }
  elseif ($Answers.SelCount -eq 1) {
    Write-Host "Your selection: $($Answers.Selections[0])"
  }
  else {
    Write-Host "Your selections: $($Answers.Selections | ft | Out-String)"
    $YesNo = Read-Host 'WARNING: Execute on multiple targets? (yes/no)'
    Write-Host ''
    if (@('y', 'yes') -notcontains $YesNo) {
      exit; break
    }
  }
}

function Parse-Answer {
  param(
    [Parameter(Mandatory = $true)][string]$ResourceType,
    [Parameter(Mandatory = $true)][psobject]$Instances,
    [Parameter(Mandatory = $true)][string]$Answer
  )

  if ($ResourceType -eq 'Configurations' -and $Answer -notmatch '^[a-z]?\d+$' -and $Answer -notmatch '^[a-z]?(:[a-z0-9-_]+)?$' -and $Answer -notmatch '^c=.*') {
    [array]$Answers = ConfigurationsActivateWildcard -Menu $instances -Wildcard $Answer
  }
  else {
    [array]$Answers = ExtractAnswersByIndex -Answer $Answer -Menu $instances
    Write-Debug "[ExtractAnswersByIndex] ``$Answer`` -> ``$($Answers.Selections | Out-String)``"
  }
  if ($null -eq $Answers) {
    [array]$Answers = ExtractAnswersByWildcard -Answer $Answer -Menu $instances
    Write-Debug "[ExtractAnswersByWildcard] ``$Answer`` -> ``$($Answers.Selections | Out-String)``"
  }
  # if ($null -eq $Answers) {
  #   $Raise_Error = "[Parse-Answer]: Unable to determine selection based on *$Answer*." ; Throw $Raise_Error     
  # }

  return $Answers
}

function Find-SelAction {
  param(
    [string]$ResourceType,
    [psobject]$SelOptions,
    [psobject]$Selections
  )

  Write-Debug "[Find-SelAction] Selections.Action= ``$($Selections.Action | Out-String)``"
  if ([string]::IsNullOrEmpty($Selections.Action)) {
    $Action = $SelOptions | Where-Object Default -EQ $true
    if ($null -eq $Action) {
      $Raise_Error = "No default action defined for ``$ResourceType``." ; Throw $Raise_Error     
    }
  }
  else {
    $Action = $SelOptions | Where-Object Hotkey -EQ $Selections.Action
    if ($null -eq $Action) {
      $Raise_Error = "[Find-SelAction]: No action defined for ``${ResourceType}``:``$($Selections.Action)``." ; Throw $Raise_Error     
    }
  }
  return $Action
}

function Invoke-Selections {
  param(
    [Parameter(Mandatory = $true)][psobject]$Selections,
    [Parameter(Mandatory = $true)][psobject]$SelAction,
    [Parameter(Mandatory = $true)][psobject]$Instances,
    ${Show-Command}
  )

  Write-Debug "[Invoke-Selections]: `$Selections: $($Selections | Out-String)"
  Write-Debug "[Invoke-Selections]: `$SelAction: $($SelAction | Out-String)"
  Write-Debug '[Invoke-Selections]: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'


  # ConEmu detection
  if (Get-Command -ErrorAction Ignore -Type Application conemu) {
    Write-Debug 'ConEmu found in path.'
    $ConEmuCmd = 'conemu'
  }
  else {
    Write-Debug 'ConEmu is running, we can get the path from there.'
    $ConEmuCmd = (Get-Process conemu* -ErrorAction Ignore | Sort-Object -Property Id | Select-Object -First 1 ).Path
  }
  if ($ConEmuCmd) {
    Write-Debug "Detected ConEmu: $ConEmuCmd"
  }

  # YQ detection
  if (Get-Command -ErrorAction Ignore -Type Application yq) {
    Write-Debug 'YQ found in path.'
    $YQCmd = 'yq'
  }
  else {
    $YQCmd = $null
  }

  $UseInternalIpCmd = $(DetectUseInternalIpSsh -Switch $UseInternalIpSsh  ).Cmd

  $ExecStyle = New-Object -TypeName PsObject -Property @{
    ShellCmd           = 'cmd';
    ShellParams        = '/c';
    WindowStyle        = 'Normal';
    SleepCmd           = '& timeout /t 60'
    AdditionalSwitches = @{}
  }

  switch -regex ($SelAction.ShellType) {
    'cmd' {
      # Already handled in default 
    }
    'hcmd' { 
      $ExecStyle.AdditionalSwitches = @{WindowStyle = 'Minimized' }
    }
    'inline.*' { 
      $ExecStyle.shellParams = '/c'; 
      $ExecStyle.SleepCmd = '& echo.';
      $ExecStyle.AdditionalSwitches = @{NoNewWindow = $true; Wait = $true }
    }
    'inlineyq' { 
      if (!($YQCmd)) { break; }
      $ExecStyle.shellParams = '/c'; 
      $ExecStyle.SleepCmd = '| yq & echo.';
      $ExecStyle.AdditionalSwitches = @{NoNewWindow = $true; Wait = $true }
    }
    'log' {
      $ExecStyle.AdditionalSwitches = @{WindowStyle = 'Maximized' };
      $ExecStyle.SleepCmd = '& pause'
    }
    'log' {
      # ConEmu
      if (!($ConEmuCmd)) { break; }
      $ExecStyle.shellCmd = $ConEmuCmd;
      $ExecStyle.shellParams = '-run';
      $ExecStyle.SleepCmd = '& pause'
      $ExecStyle.AdditionalSwitches = @{WindowStyle = 'Maximized' };
    }
    'out-gridview' {
    }
    'show-command' {
      ${Show-Command} = $true
    }
    default { $Raise_Error = "Unexpected exec type: $type" ; Throw $Raise_Error }
  }

  $Param = $Selections.Param
  foreach ($Sel in $Selections.Selections) {
    Write-Debug "Executing selection: ``$sel``"

    if ($null -ne $SelAction.TaskPrep) {
      Write-Debug "[Invoke-Selections] Starting `$TaskPrep:``$TaskPrep``"
      $TaskPrep = Invoke-Command -ScriptBlock $SelAction.TaskPrep
      Write-Debug "[Invoke-Selections] `$TaskPrep done:``$TaskPrep``"
    }
    
    $argListMid = $ExecutionContext.InvokeCommand.ExpandString($SelAction.ShellArgsMid)
    Write-Verbose "argListMid: `"$argListMid`""
    $argList = "$($ExecStyle.shellParams) gcloud $argListMid $($ExecStyle.SleepCmd)"
    Write-Debug "[Invoke-Selections] `$argList:``$argList``"
    if ($SelAction.ShellType -eq 'out-gridview') {
      return
    }
    if (${Show-Command}) {
      Write-Output "COMMAND: gcloud $argListMid`n"
      continue
    }  
    $AdditionalSwitches = $ExecStyle.AdditionalSwitches
  
    Write-Debug "[Invoke-Selections]: `$ExecStyle: $ExecStyle"
  
    Start-Process $($ExecStyle.ShellCmd) -ArgumentList "$argList " @AdditionalSwitches -Verbose
  
    if ($null -ne $SelAction.TaskPost) {
      Write-Debug "[Invoke-Selections] Starting `$TaskPost:"
      $TaskPost = Invoke-Command -ScriptBlock $SelAction.TaskPost
      Write-Debug "`$TaskPost done: $TaskPost"
    }

    if ($type -eq 'inline') {
      Write-Host ''
    }
  
  }
}


function Get-EnvPathsArr {
  Param([ValidateSet('User', 'Machine', 'All')]$Scope = 'All')

  $Paths = @() 
  if ( @('Machine', 'All') -icontains $Scope) {
    $Paths += `
      [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
  }
 
  if ( @('User', 'All') -icontains $Scope) {
    $Paths += `
      [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
  }

  return $Paths
}

function Install-Script {
  if (Get-EnvPathsArr('All') -notcontains $PSScriptRoot) {
    Write-Output 'INSTALL: Adding script location to %PATH% as user env var...'
  
    [Environment]::SetEnvironmentVariable('Path', "$((Get-EnvPathsArr('User')) -join ';');$PSScriptRoot", [System.EnvironmentVariableTarget]::User)
  }
  
  if ($env:Path -split ';' -notcontains $PSScriptRoot) {
    Write-Output 'INSTALL: Refreshing %PATH% in current shell...'
    $env:Path = "$PSScriptRoot;$env:Path"
  }
  else {
    Write-Output 'INSTALL: $PSScriptRoot already in %PATH%'
  }
}

function Get-FilePicker($initialDirectory) {
  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.initialDirectory = $initialDirectory
  $OpenFileDialog.filter = "All Files (*.*)|*.*"
  $OpenFileDialog.ShowDialog() | Out-Null
  $OpenFileDialog.filename
}

function Get-FolderPicker($initialDirectory) {
  [System.Reflection.Assembly]::LoadWithPartialName("system.windows.forms") | Out-Null
  $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
  $foldername.Description = "Select a folder"
  $foldername.SelectedPath = $initialDirectory
  if ($foldername.ShowDialog() -eq "OK") {
    $folder += $foldername.SelectedPath
  }
  return $folder
}
  
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

function Get-FileOrFolderPicker($initialDirectory) {
  # Example usage:
  # $selectedPath = Get-FileOrFolderPicker "C:\"

  # Create the form
  $form = New-Object System.Windows.Forms.Form
  $form.Text = "Select a File or Folder"
  $form.Size = New-Object System.Drawing.Size(400, 500)
  $form.StartPosition = "CenterScreen"

  # Create the TreeView
  $treeView = New-Object System.Windows.Forms.TreeView
  $treeView.Location = New-Object System.Drawing.Point(10, 10)
  $treeView.Size = New-Object System.Drawing.Size(360, 400)
  $treeView.PathSeparator = "\"
  $form.Controls.Add($treeView) | Out-Null

  # OK Button
  $okButton = New-Object System.Windows.Forms.Button
  $okButton.Location = New-Object System.Drawing.Point(150, 420)
  $okButton.Size = New-Object System.Drawing.Size(75, 23)
  $okButton.Text = "OK"
  $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $form.AcceptButton = $okButton
  $form.Controls.Add($okButton) | Out-Null

  # Cancel Button
  $cancelButton = New-Object System.Windows.Forms.Button
  $cancelButton.Location = New-Object System.Drawing.Point(230, 420)
  $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
  $cancelButton.Text = "Cancel"
  $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $form.CancelButton = $cancelButton
  $form.Controls.Add($cancelButton) | Out-Null

  # Function to populate TreeView with directories and files
  function Populate-TreeView($treeView, $path) {
    $treeView.Nodes.Clear()
    $rootNode = New-Object System.Windows.Forms.TreeNode($path)
    $rootNode.Tag = $path
    [void]$treeView.Nodes.Add($rootNode)

    # Add subdirectories
    try {
      $dirs = Get-ChildItem -Path $path -Directory -ErrorAction Stop
      foreach ($dir in $dirs) {
        $dirNode = New-Object System.Windows.Forms.TreeNode($dir.Name)
        $dirNode.Tag = $dir.FullName
        [void]$dirNode.Nodes.Add("Loading...")
        [void]$rootNode.Nodes.Add($dirNode)
      }

      # Add files
      $files = Get-ChildItem -Path $path -File -ErrorAction Stop
      foreach ($file in $files) {
        $fileNode = New-Object System.Windows.Forms.TreeNode($file.Name)
        $fileNode.Tag = $file.FullName
        [void]$rootNode.Nodes.Add($fileNode)
      }
    }
    catch {
      [System.Windows.Forms.MessageBox]::Show("Error accessing $path`: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    $rootNode.Expand() | Out-Null
  }

  # Event to lazy-load subdirectories
  $treeView.add_BeforeExpand({
      $node = $_.Node
      if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "Loading...") {
        $node.Nodes.Clear()
        $path = $node.Tag
        try {
          $dirs = Get-ChildItem -Path $path -Directory -ErrorAction Stop
          foreach ($dir in $dirs) {
            $dirNode = New-Object System.Windows.Forms.TreeNode($dir.Name)
            $dirNode.Tag = $dir.FullName
            [void]$dirNode.Nodes.Add("Loading...")
            [void]$node.Nodes.Add($dirNode)
          }

          $files = Get-ChildItem -Path $path -File -ErrorAction Stop
          foreach ($file in $files) {
            $fileNode = New-Object System.Windows.Forms.TreeNode($file.Name)
            $fileNode.Tag = $file.FullName
            [void]$node.Nodes.Add($fileNode)
          }
        }
        catch {
          [System.Windows.Forms.MessageBox]::Show("Error accessing $path`: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
      }
    })

  # Populate the TreeView with the initial directory
  if (-not $initialDirectory) { $initialDirectory = "C:\" }
  Populate-TreeView -treeView $treeView -path $initialDirectory

  # Show the form and return the selected path
  $form.Topmost = $true
  $result = $form.ShowDialog()

  if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $treeView.SelectedNode -ne $null) {
    return $treeView.SelectedNode.Tag
  }
  return $null
}
