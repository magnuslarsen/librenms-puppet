# @summary Manages all SNMP resources
#
# Manages all SNMP resources
#
# @example
#   use main class
class librenms::snmp {
  $_contact = $librenms::snmp_contact ? {
    undef   => $librenms::config_admin_email,
    default => $librenms::snmp_contact,
  }

  if empty($librenms::snmp_trap_mib_dirs) {
    $mib_dirs = "${librenms::vcs_root_dir}/mibs"
  }
  else {
    $mib_dirs = join($librenms::snmp_trap_mib_dirs, ':')
  }

  class { 'snmp':
    autoupgrade           => true,
    contact               => $_contact,
    ensure                => $librenms::snmp_package_ensure,
    location              => $librenms::snmp_location,
    manage_client         => true,
    ro_community          => $librenms::snmp_ro_community,

    # trapd config: https://docs.librenms.org/Extensions/SNMP-Trap-Handler/
    trap_service_enable   => $librenms::snmp_trap_enabled,
    trap_service_ensure   => $librenms::snmp_trap_ensure,
    trap_handlers         => [
      "default ${librenms::vcs_root_dir}/snmptrap.php",
    ],
    disable_authorization => 'yes',
  }

  file { '/etc/systemd/system/snmptrapd.service.d/':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/systemd/system/snmptrapd.service.d/mibs.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    content => @("CONTENT"/L),
      [Service]
      Environment=MIBDIRS=+${mib_dirs}
      Environment=MIBS=+${join($librenms::snmp_trap_mibs, ':')}
      | CONTENT
  }

  exec { 'librenms_snmptrapd_reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/etc/systemd/system/snmptrapd.service.d/mibs.conf'],
    notify      => Service['snmptrapd']
  }

}
