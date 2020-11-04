# @summary Manages all Oxidized resources
#
# Manages all Oxidized resources
#
# @example
#   use main class
class librenms::oxidized {
  if $librenms::oxidized_enabled {
    $http_protocol = $librenms::nginx_ssl_enable ? {
      false => 'http',
      true  => 'https',
    }

    $sane_default = {
      'interval'   => 1800,
      'use_syslog' => false,
      'debug'      => false,
      'threads'    => 40,
      'timeout'    => 60,
      'retries'    => 0,
      'prompt'     => '!ruby/regexp /^([\w.@-]+[#>]\s?)$/',
      'rest'       => '127.0.0.1:8888',
      'vars'       => {
        'remove_secret' => true,
      },
      'source'     => {
        'default' => 'http',
        'debug'   => false,
        'http'    => {
          'url' => "${http_protocol}://${librenms::nginx_server_name}/api/v0/oxidized",
          'map' => {
            'name'  => 'hostname',
            'model' => 'os',
            'group' => 'group',
          },
          'headers' => {
            'X-Auth-Token' => $librenms::oxidized_auth_token,
          },
        },
      },
      'input' => {
        'default' => 'ssh', # Yes, this is a string
        'debug'   => false,
        'ssh'     => {
          'secure' => true,
        },
      },
      'output' => {
        'default' => 'git',
        'git'     => {
          'user'        => 'oxidized',
          'single_repo' => true,
          'repo'        => '/home/oxidized/.config/oxidized/devices.git',
          'email'       => $librenms::config_admin_email,
        },
      },
    }

    $config = deep_merge($sane_default, $librenms::oxidized_configuration)

    class { 'oxidized':
      manage_repo          => $librenms::oxidized_manage_repo,
      with_web             => true,
      with_service         => true,
      config               => $config,
      log                  => $librenms::oxidized_log_path,
      install_dependencies => $librenms::oxidized_install_packages,
      ruby_dependencies    => $librenms::oxidized_ruby_packages,
      require              => Service['nginx'],
    }
  }
}
