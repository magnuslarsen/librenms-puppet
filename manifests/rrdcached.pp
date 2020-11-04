# @summary Manages all RRD and RRDCache resources
#
# Manages all RRD and RRDCache resources
#
# @example
#   use main class
class librenms::rrdcached {
  file { '/etc/default/rrdcached':
    ensure  => file,
    owner   => $librenms::librenms_owner,
    group   => $librenms::librenms_group,
    mode    => '0755',
    content => epp("${module_name}/rrdcached.epp", {
      pid_file    => $librenms::rrdcached_pid_file,
      socket_file => $librenms::rrdcached_socket_file,
      owner       => $librenms::librenms_owner,
      group       => $librenms::librenms_group,
      vcs_dir     => $librenms::vcs_root_dir
    }),
    notify  => Service['rrdcached'],
  }

  file { '/var/lib/rrdcached/journal':
    ensure => directory,
    owner  => $librenms::librenms_owner,
    group  => $librenms::librenms_group,
  }

  service { 'rrdcached':
    ensure  => running,
    enable  => true,
    require => [
      Package['rrdcached'],
      File['/etc/default/rrdcached', '/var/lib/rrdcached/journal'],
    ],
  }
}
