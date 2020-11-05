# @summary Manages all Web related resources (NGINX, PHP and FPM)
#
# Manages all Web related resources (NGINX, PHP and FPM)
#
# @example
#   use main class
class librenms::web_services {
  $default = {
    'Date/date.timezone' => 'Etc/UTC',
  }

  $settings = deep_merge($default, $librenms::php_configuration)

  class { 'php':
    ensure       => $librenms::php_package_ensure,
    fpm          => true,
    fpm_user     => $librenms::librenms_owner,
    fpm_group    => $librenms::librenms_group,
    dev          => true,
    composer     => true,
    pear         => true,
    settings     => $settings,
    manage_repos => $librenms::php_manage_repo,
    extensions   => {
      'curl'     => {},
      'gd'       => {},
      'json'     => {},
      'ldap'     => {},
      'mbstring' => {},
      'mysql'    => {},
      'snmp'     => {},
      'xml'      => {},
      'zip'      => {},
    },
  }

  # Run the provided librenms install script
  exec { 'librenms_composer_script':
    command     => "${librenms::vcs_root_dir}/scripts/composer_wrapper.php install --no-dev",
    user        => $librenms::librenms_owner,
    refreshonly => true,
    require     => Vcsrepo[$librenms::vcs_root_dir],
    subscribe   => Class['::php'],
  }

  class { 'nginx':
    manage_repo  => $librenms::nginx_manage_repo,
    global_owner => $librenms::librenms_owner,
    global_group => $librenms::librenms_group,
  }

  nginx::resource::server { $librenms::nginx_server_name:
    www_root                  => "${librenms::vcs_root_dir}/html",
    use_default_location      => false,
    index_files               => ['index.php'],
    gzip_types                => 'text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon', #lint:ignore:140chars
    # TLS settings
    http2                     => $librenms::nginx_http2_enable,
    listen_port               => $librenms::nginx_listen_port,
    ssl                       => $librenms::nginx_ssl_enable,
    ssl_buffer_size           => $librenms::nginx_ssl_buffer_size,
    ssl_cache                 => $librenms::nginx_ssl_cache,
    ssl_cert                  => $librenms::nginx_ssl_cert,
    ssl_ciphers               => $librenms::nginx_ssl_ciphers,
    ssl_client_cert           => $librenms::nginx_ssl_client_cert,
    ssl_crl                   => $librenms::nginx_ssl_crl,
    ssl_dhparam               => $librenms::nginx_ssl_dhparam,
    ssl_ecdh_curve            => $librenms::nginx_ssl_ecdh_curve,
    ssl_key                   => $librenms::nginx_ssl_key,
    ssl_listen_option         => $librenms::nginx_ssl_listen_option,
    ssl_port                  => $librenms::nginx_ssl_port,
    ssl_prefer_server_ciphers => $librenms::nginx_ssl_prefer_server_ciphers,
    ssl_protocols             => $librenms::nginx_ssl_protocols,
    ssl_redirect              => $librenms::nginx_ssl_enable,
    ssl_redirect_port         => $librenms::nginx_ssl_redirect_port,
    ssl_session_ticket_key    => $librenms::nginx_ssl_session_ticket_key,
    ssl_session_tickets       => $librenms::nginx_ssl_session_tickets,
    ssl_session_timeout       => $librenms::nginx_ssl_session_timeout,
    ssl_stapling              => $librenms::nginx_ssl_stapling,
    ssl_stapling_file         => $librenms::nginx_ssl_stapling_file,
    ssl_stapling_responder    => $librenms::nginx_ssl_stapling_responder,
    ssl_stapling_verify       => $librenms::nginx_ssl_stapling_verify,
    ssl_trusted_cert          => $librenms::nginx_ssl_trusted_cert,
    ssl_verify_client         => $librenms::nginx_ssl_verify_client,
    ssl_verify_depth          => $librenms::nginx_ssl_verify_depth,
    add_header                => $librenms::nginx_ssl_headers,
    # Dependencies
    require                   => [
      Vcsrepo[$librenms::vcs_root_dir],
      Class['::php', '::mysql::server'],
    ],
  }

  php::fpm::pool { 'librenms':
    listen                 => '/var/run/php-fpm/php-fpm.sock',
    listen_allowed_clients => '127.0.0.1',
    ping_path              => '/fpm-ping',
    pm_status_path         => '/fpm-status',
    # www-data is expected by librenms, regardless of running user
    listen_owner           => 'www-data',
    listen_group           => 'www-data',
    # Tuning options
    pm                     => $librenms::php_fpm_pm,
    pm_max_children        => $librenms::php_fpm_pm_max_children,
    pm_start_servers       => $librenms::php_fpm_pm_start_servers,
    pm_min_spare_servers   => $librenms::php_fpm_pm_min_spare_servers,
    pm_max_spare_servers   => $librenms::php_fpm_pm_max_spare_servers,
  }
  -> nginx::resource::location { '/':
    server      => $librenms::nginx_server_name,
    index_files => [],
    try_files   => ['$uri', '$uri/', '/index.php?$query_string'],
    ssl         => $librenms::nginx_ssl_enable,
    ssl_only    => $librenms::nginx_ssl_enable,
  }
  -> nginx::resource::location { '/api/v0':
    server      => $librenms::nginx_server_name,
    index_files => [],
    try_files   => ['$uri', '$uri/', '/api_v0.php?$query_string'],
    ssl         => $librenms::nginx_ssl_enable,
    ssl_only    => $librenms::nginx_ssl_enable,
  }
  -> nginx::resource::location { '~ \.php':
    server              => $librenms::nginx_server_name,
    fastcgi             => 'unix:/var/run/php-fpm/php-fpm.sock',
    fastcgi_split_path  => '^(.+\.php)(/.+)$',
    ssl                 => $librenms::nginx_ssl_enable,
    ssl_only            => $librenms::nginx_ssl_enable,
    location_cfg_append => {
      'fastcgi_read_timeout' => $librenms::nginx_fastcgi_read_timeout,
    },
  }
  -> nginx::resource::location { '~ /\.ht':
    server        => $librenms::nginx_server_name,
    location_deny => ['all'],
    index_files   => [],
    ssl           => $librenms::nginx_ssl_enable,
    ssl_only      => $librenms::nginx_ssl_enable,
  }

  # Remove the default site
  file { '/etc/nginx/sites-enabled/default':
    ensure => 'absent',
    notify => Service['nginx'],
  }

  # Enable the monitoring pages, if specified
  if $librenms::nginx_enable_mon_sites {
    file { '/etc/nginx/sites-available/monitor_pages.conf':
      ensure  => file,
      content => file("${module_name}/monitor_pages.conf"),
    }
    -> file { '/etc/nginx/sites-enabled/monitor_pages.conf':
      ensure => link,
      target => '/etc/nginx/sites-available/monitor_pages.conf',
      notify => Service['nginx'],
    }
  }
}
