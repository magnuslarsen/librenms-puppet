# @summary Manages the Weathermap plugin for LibreNMS
#
# Manages the Weathermap plugin for LibreNMS
#
# @example
#   use main class
class librenms::weathermap {
  if $librenms::weathermap_enabled {
    # Always use the latest branch
    vcsrepo { "${librenms::vcs_root_dir}/html/plugins/Weathermap":
      ensure   => 'latest',
      branch   => 'master',
      provider => 'git',
      source   => 'https://github.com/librenms-plugins/Weathermap.git',
      owner    => $librenms::librenms_owner,
      group    => $librenms::librenms_group,
      require  => Vcsrepo[$librenms::vcs_root_dir],
    }
  }
}
