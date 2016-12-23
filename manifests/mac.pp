# migrate mac's to puppet 4
# puppet-agent-<PACKAGE VERSION>.osx<OS X VERSION>.dmg eg puppet-agent-1.3.2.osx10.11.dmg
# $facts['macosx_productversion_major']
# we want agent 1.8.2
# https://downloads.puppetlabs.com/mac/10.11/PC1/x86_64/puppet-agent-1.8.2-1.osx10.11.dmg
# https://downloads.puppetlabs.com/mac/10.12/PC1/x86_64/puppet-agent-1.8.2-1.osx10.12.dmg
class migrate::mac {
  $mac_vers = $facts['macosx_productversion_major']

  file {'/etc/puppetlabs':
    ensure => directory,
  }
  ->
  file {'/etc/puppetlabs/puppet':
    ensure => directory,
  }
  ->
  file {'/etc/puppetlabs/puppet/puppet.conf':
    ensure => present,
    source => 'puppet:///modules/migrate/puppet.conf'
  }

  package {"puppet-agent-1.8.2-1.osx${mac_vers}.dmg":
    ensure => present,
    source => "https://downloads.puppetlabs.com/mac/${mac_vers}/PC1/x86_64/puppet-agent-1.8.2-1.osx${mac_vers}.dmg"
  }

  $time1  =  fqdn_rand(30)
  $time2  =  $time1 + 30
  $minute = [ $time1, $time2 ]

  cron {'puppet-agent':
    command => '/opt/puppetlabs/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
    user    => 'root',
    hour    => '*',
    minute  => $minute,
  }

  file {'/etc/puppet':
    ensure => purged,
    force  => true,
  }
  ->
  file { '/var/lib/puppet/ssl':
    ensure => purged,
    force  => true,
  }
  ->
  package {'puppet':
    ensure   => absent,
    provider => 'gem',
  }
}
