# - create /etc/puppetlabs/puppet/puppet.conf
# - set server, ca server, and ca port
# - add puppet collections repo
# - rm /etc/puppet/
# - rm /var/lib/puppet
# - install puppet-agent
# - put cronjob in place
#
class migrate {

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

  if $facts['osfamily'] == 'Debian' {
    include apt
    apt::source { 'puppetlabs-pc1':
      location => 'http://apt.puppetlabs.com',
      repos    => 'PC1',
      key      => {
        'id'     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
        'server' => 'pgp.mit.edu',
      },
      notify   => Class['apt::update']
    }
    package {'puppet-agent':
      ensure  => present,
      require => Class['apt::update']
    }
  }

  if $facts['osfamily'] == 'RedHat' {
    $version = $facts['operatingsystemmajrelease']
    yumrepo {'puppetlabs-pc1':
      baseurl  => "https://yum.puppetlabs.com/el/${version}/PC1/\$basearch",
      descr    => 'Puppetlabs PC1 Repository',
      enabled  => true,
      gpgcheck => '1',
      gpgkey   => 'https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs'
    }
    ->
    package {'puppet-agent':
      ensure => present,
    }
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
  ->
  cron {'puppet-client':
    ensure  => 'absent',
    command => '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
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
}
