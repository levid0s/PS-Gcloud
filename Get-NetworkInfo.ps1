function Get-NetworkInfo {

    $configs = Get-NetIPConfiguration

    $networkInfo = @()
    
    foreach ($config in $configs) {
        $index = $config.InterfaceIndex
        $name = $config.InterfaceAlias
        $status = $config.NetAdapter.Status
        $macAddress = $config.NetAdapter.MacAddress
        $linkSpeed = $config.NetAdapter.LinkSpeed
        $dnsc = Get-DnsClient -InterfaceIndex $index
        $dnss = @($dnsc.ConnectionSpecificSuffix)
        $dnss += $dnsc.ConnectionSpecificSuffixSearchList
        $dnsl = $($dnss | Where-Object { $_ }) -join ', '


        if ($config.NetIPv4Interface) {
            $ip = $config.IPv4Address.IPaddress -join "`n"
            $netmask = ($config.IPv4Address.PrefixLength | % { "/$_" }) -join "`n"
            $gateway = $config.IPv4DefaultGateway.NextHop
            $ifMetric = $config.IPv4DefaultGateway.InterfaceMetric
            $dnsServers = ($config.DNSServer | ? { $_.AddressFamily -eq 2 } | select -ExpandProperty ServerAddresses ) -join ', '

            $networkInfo += [pscustomobject]@{
                'Name'        = $name
                'Family'      = 'IPv4'
                'IP Address'  = $ip
                'Netmask'     = $netmask
                'Gateway'     = $gateway
                'DNS Servers' = $dnsServers
                'DNS Search'  = $dnsl
                'Status'      = $status
                'MacAddress'  = $macAddress
                'LinkSpeed'   = $linkSpeed
                'ifMetric'    = $ifMetric
                'ifIndex'     = $index
            }
        }

        if ($config.NetIPv6Interface) {
            $ips = @()
            $ips += $config.IPv6Address.IPaddress
            $ips += (Get-NetIPAddress -AddressFamily IPv6 -InterfaceIndex $index | select -ExpandProperty IPAddress)

            $ip = ($ips | Where-Object { $_ }) -join "`n"
            $gateway = $config.IPv6DefaultGateway.NextHop
            $ifMetric = $config.IPv6DefaultGateway.InterfaceMetric
            $dnsServers = ($config.DNSServer | ? { $_.AddressFamily -eq 23 } | select -ExpandProperty ServerAddresses ) -join ', '

            $networkInfo += [pscustomobject]@{
                'Name'        = $name
                'Family'      = 'IPv6'
                'IP Address'  = $ip
                'Netmask'     = '/128'  # IPv6 doesn't have a traditional netmask
                'Gateway'     = $gateway
                'DNS Servers' = $dnsServers
                'DNS Search'  = $dnsl
                'Status'      = $status
                'MacAddress'  = $macAddress
                'LinkSpeed'   = $linkSpeed
                'ifMetric'    = $ifMetric
                'ifIndex'     = $index
            }
        }
    }

    $networkInfo | Out-GridView
}

Get-NetworkInfo