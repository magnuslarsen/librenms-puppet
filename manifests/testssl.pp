# @summary Manages the TestSSL plugin for LibreNMS
#
# Manages the TestSSL plugin for LibreNMS
#
# @example
#   use main class
class librenms::testssl {
  # Always use the latest branch
  if $librenms::testssl_enabled {
    vcsrepo { "${librenms::vcs_root_dir}/html/plugins/TestSSL":
      ensure   => 'latest',
      provider => 'git',
      source   => 'https://github.com/drwetter/testssl.sh',
      owner    => $librenms::librenms_owner,
      group    => $librenms::librenms_group,
      require  => Vcsrepo[$librenms::vcs_root_dir],
    }

    file { "${librenms::vcs_root_dir}/html/plugins/TestSSL/tmp":
      ensure  => directory,
      owner   => $librenms::librenms_owner,
      group   => $librenms::librenms_group,
      mode    => '0755',
      require => Vcsrepo["${librenms::vcs_root_dir}/html/plugins/TestSSL"],
    }

    file { "${librenms::vcs_root_dir}/html/plugins/TestSSL/TestSSL.php":
      ensure  => file,
      owner   => $librenms::librenms_owner,
      group   => $librenms::librenms_group,
      mode    => '0755',
      content => file("${module_name}/TestSSL.php"),
      require => Vcsrepo["${librenms::vcs_root_dir}/html/plugins/TestSSL"],
    }

    file { "${librenms::vcs_root_dir}/html/plugins/TestSSL/TestSSL.inc.php":
      ensure  => file,
      owner   => $librenms::librenms_owner,
      group   => $librenms::librenms_group,
      mode    => '0755',
      content => epp("${module_name}/TestSSL.inc.php", {
        fqdn    => $librenms::nginx_server_name
      }),
      require => Vcsrepo["${librenms::vcs_root_dir}/html/plugins/TestSSL"],
    }
  }
}
