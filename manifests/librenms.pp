# @summary Manages all LibreNMS resources
#
# Manages all LibreNMS resources
#
# @example
#   use main class
class librenms::librenms {
  vcsrepo { $librenms::vcs_root_dir:
    ensure   => $librenms::vcs_ensure,
    branch   => $librenms::vcs_branch,
    provider => 'git',
    source   => 'https://github.com/librenms/librenms.git',
    depth    => 1,
    owner    => $librenms::librenms_owner,
    group    => $librenms::librenms_group,
    before   => [
      Class['::mysql::server::backup'],
      File[$librenms::vcs_root_dir],
    ],
  }

  # Make use of the built-in cronjobs
  file { '/etc/cron.d/librenms':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp("${module_name}/librenms.cron.epp", {
      poller_threads     => $librenms::config_poller_threads,
      discover_threads   => $librenms::config_discover_threads,
      librenms_user      => $librenms::librenms_owner,
      vcs_root           => $librenms::vcs_root_dir,
      weathermap_enabled => $librenms::weathermap_enabled,
      testssl_enabled    => $librenms::testssl_enabled,
    }),
    require => Vcsrepo[$librenms::vcs_root_dir],
  }

  # Make use of the built-in logrotate configuration
  file { '/etc/logrotate.d/librenms':
    ensure  => file,
    owner   => $librenms::librenms_owner,
    group   => $librenms::librenms_group,
    mode    => '0644',
    source  => "file://${librenms::vcs_root_dir}/misc/librenms.logrotate",
    require => Vcsrepo[$librenms::vcs_root_dir],
  }

  # The main config file..
  $formatted_raw_input = to_phpconfig($librenms::config_raw_input)
  file { "${librenms::vcs_root_dir}/config.php":
    ensure  => file,
    owner   => $librenms::librenms_owner,
    group   => $librenms::librenms_group,
    mode    => '0640',
    content => template("${module_name}/config.php.erb"),
    require => Vcsrepo[$librenms::vcs_root_dir],
  }

  # These two files need special permissions, which doesn't come out of the box :shrug:
  file { ["${librenms::vcs_root_dir}/bootstrap/cache/services.php", "${librenms::vcs_root_dir}/bootstrap/cache/packages.php"]:
    ensure  => file,
    owner   => $librenms::librenms_owner,
    group   => $librenms::librenms_group,
    mode    => '0775',
    require => Vcsrepo[$librenms::vcs_root_dir],
  }
}
