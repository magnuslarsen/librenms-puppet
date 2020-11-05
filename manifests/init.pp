# @summary Manages the whole LibreNMS installation, on a single node
#
# Manages the whole LibreNMS installation, on a single node
#
# @example
#   # LibreNMS with Oxidized + Weathermap plugins, active Netscaler poller, AD logins, and sample TLS config
#   class { '::librenms':
#     config_admin_email              => $admin_email,
#     config_poller_threads           => 32,
#     mysql_librenms_password         => $mysql_librenms_password,
#     mysql_root_password             => $mysql_root_password,
#     oxidized_auth_token             => $oxidized_api_token,
#     oxidized_enabled                => true,
#     oxidized_manage_repo            => true,
#     snmp_location                   => 'Null Island',
#     snmp_ro_community               => $snmp_ro_community,
#     weathermap_enabled              => true,
#     config_override_pollers         => {
#       'netscaler-vsvr' => 1,
#     },
#     config_raw_input                => {
#       'active_directory.users_purge'         => 14, # days
#       'auth_ad_base_dn'                      => 'DC=domain,DC=com',
#       'auth_ad_bindpassword'                 => $ad_bind_password,
#       'auth_ad_binduser'                     => $ad_bind_username,
#       'auth_ad_check_certificates'           => 0,
#       'auth_ad_domain'                       => 'domain.com',
#       'auth_ad_groups.LibreNMS_Admins.level' => 10,
#       'auth_ad_groups.LibreNMS_Users.level'  => 5,
#       'auth_ad_require_groupmembership'      => 1,
#       'auth_ad_url'                          => 'ldaps://domain.com',
#       'auth_mechanism'                       => 'active_directory',
#       'authlog_purge'                        => 15, # days
#       'oxidized.enabled'                     => true,
#       'oxidized.url'                         => 'http://127.0.0.1:8888',
#       'oxidized.group_support'               => true,
#       'oxidized.features.versioning'         => true,
#       'oxidized.reload_nodes'                => false,
#       'oxidized.group.os'                    => [
#         { 'match' => 'asa',       'group' => 'cisco-asa-device' },
#         { 'match' => 'ios',       'group' => 'cisco-device' },
#         { 'match' => 'iosxe',     'group' => 'cisco-device' },
#         { 'match' => 'netscaler', 'group' => 'netscaler-device' },
#         { 'match' => 'procurve',  'group' => 'procurve-device' },
#       ],
#       'oxidized.group.hostname'              => [
#         { 'regex' => '/^switch\d.*/', 'group' => 'switches' },
#         { 'regex' => '/^router\d.*/', 'group' => 'routers' },
#       ],
#     }
#     # TLS settings are primary taken from these:
#     # https://ssl-config.mozilla.org/#server=nginx&config=intermediate&ocsp=false
#     # https://cipherli.st/
#     nginx_ssl_enable                => true,
#     nginx_ssl_protocols             => 'TLSv1.2 TLSv1.3',
#     nginx_ssl_ciphers               => 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384', #lint:ignore:140chars
#     nginx_ssl_cert                  => "${cert_root_path}/full_cert.pem",
#     nginx_ssl_key                   => "${cert_root_path}/cert.key",
#     nginx_ssl_prefer_server_ciphers => 'on',
#     nginx_ssl_cache                 => 'shared:ssl_cache:10m',
#     nginx_ssl_session_tickets       => 'off',
#     nginx_ssl_session_timeout       => '1d',
#     nginx_ssl_dhparam               => "${cert_root_path}/dhparam.pem",
#     nginx_ssl_headers               => {
#       'Strict-Transport-Security' => 'max-age=31557600',
#       'X-Frame-Options'           => 'DENY',
#       'X-Content-Type-Options'    => 'nosniff',
#       'X-XSS-Protection'          => '1; mode=block',
#     },
#     oxidized_configuration          => {
#       'groups'    => $oxidized_config_groups,
#       'input'     => {
#         'ssh' => {
#           'secure' => false, # Disable hostkey verification
#         },
#       },
#       'model_map' => {
#         'procurve'   => 'procurve',
#         'cisco'      => 'ios',
#         'asa'        => 'asa',
#         'ciscowlc'   => 'aireos',
#         'arista'     => 'eos'
#       },
#     },
#   }
#
# @param config_admin_email              The admin email used for Oxidized and SNMP contact (required)
# @param config_discover_threads         The number of discover pollers should be running at a time
# @param config_override_pollers         A hash of pollers to enable (1) or disable (0)
# @param config_poller_threads           The number of pollers should be running at a time
# @param config_raw_input                A hash of configuration options for LibreNMS
# @param cron_manage_service             Whether to manage the Cron service or not
# @param import_mysqldump                An optional mysqldump to import
# @param librenms_group                  The LibreNMS Linux group name
# @param librenms_owner                  The LibreNMS Linux owner name
# @param mysql_backup_revisions          The number of mysql backup revisions to keep on disk
# @param mysql_client_package_ensure     The ensure value for MySQL client
# @param mysql_client_package_name       The package name for MySQL client
# @param mysql_configuration             A hash of configuration options for MySQL
# @param mysql_librenms_password         The password for the LibreNMS database user (required)
# @param mysql_librenms_username         The username for the LibreNMS database user
# @param mysql_root_password             The password for the root database user (required)
# @param mysql_server_package_ensure     The ensure value for MySQL server
# @param mysql_server_package_name       The package name for MySQL server
# @param nginx_enable_mon_sites          Whether to enable monitoring pages for NGINX and PHP-FPM
# @param nginx_fastcgi_read_timeout      The number of seconds before the timeout error in NGINX occurs
# @param nginx_http2_enable              Whether to enable http2 or not
# @param nginx_listen_port               The NGINX listen port (http)
# @param nginx_manage_repo               Whether to manage the NGINX repo or not
# @param nginx_server_name               The NGINX server name
# @param nginx_ssl_buffer_size           The size of the buffer used for sending data
# @param nginx_ssl_cache                 The cache string to use (e.g. 'shared:ssl_cache:10m')
# @param nginx_ssl_cert                  Path to the certificate
# @param nginx_ssl_ciphers               Colon seperated string of ciphers to use
# @param nginx_ssl_client_cert           Path to a client reference certificate
# @param nginx_ssl_crl                   Path to a file of revoked certificates
# @param nginx_ssl_dhparam               Path to the DHPARAM file
# @param nginx_ssl_ecdh_curve            Which ECDH curve to use
# @param nginx_ssl_enable                Whether to enable SSL/TLS or not
# @param nginx_ssl_headers               A hash of SSL/TLS headers to use
# @param nginx_ssl_key                   Path to the certificate key
# @param nginx_ssl_listen_option         Whether to listen for SSL/TLS traffic or not
# @param nginx_ssl_port                  The NGINX listen port (https)
# @param nginx_ssl_prefer_server_ciphers Whether to prefer SSL/TLS ciphers or not
# @param nginx_ssl_protocols             Space seperated string of SSL/TLS protocols to use
# @param nginx_ssl_redirect_port         Override $nginx_ssl_port for redirects (generally not needed)
# @param nginx_ssl_session_ticket_key    A file containing the secret key used to encrypt and decrypt SSL/TLS session tickets
# @param nginx_ssl_session_tickets       Whether to use session tickets or not
# @param nginx_ssl_session_timeout       How long before ssl session times out (e.g. '1d')
# @param nginx_ssl_stapling              Whether to enable OCSP responses or not
# @param nginx_ssl_stapling_file         When set, the stapled OCSP response will be taken from the specified file instead of querying the OCSP responder specified in the server certificate
# @param nginx_ssl_stapling_responder    Overrides the URL of the OCSP responder specified in the Authority Information Access certificate extension
# @param nginx_ssl_stapling_verify       Whether to enable OCSP verification or not
# @param nginx_ssl_trusted_cert          Path to a file of trusted certificates
# @param nginx_ssl_verify_client         Whether to verify clients certificates or not
# @param nginx_ssl_verify_depth          How deep in the client certificates chain to verify
# @param oxidized_auth_token             An API token for the Oxidized user (create on in LibreNMS)
# @param oxidized_configuration          A hash of configuration options for Oxidized
# @param oxidized_enabled                Whether to enable Oxidized or not
# @param oxidized_install_packages       An array of packages to install before Oxidized
# @param oxidized_log_path               The path to the Oxidized log
# @param oxidized_manage_repo            Whether to manage the Oxidized repo or not
# @param oxidized_ruby_packages          An array of gems to install before Oxidized
# @param php_configuration               A hash of configuration options for PHP
# @param php_fpm_pm                      The process management state (`dynamic` or `static`)
# @param php_fpm_pm_max_children         The maximum number of child processes to run
# @param php_fpm_pm_max_spare_servers    The maximum amount of idle child processes to run
# @param php_fpm_pm_min_spare_servers    The minimum amount of idle child processes to run
# @param php_fpm_pm_start_servers        The amount of child processes to run on start-up
# @param php_manage_repo                 Whether to manage the PHP repo or not
# @param php_package_ensure              The ensure value for PHP
# @param rrd_backup_revisions            The number of RRD backup revisions to keep on disk
# @param rrdcached_pid_file              The path to the PID file for RRDCached
# @param rrdcached_socket_file           The path to the socket file for RRDCached
# @param snmp_contact                    The SNMP contact to be listed (overrides $config_admin_email)
# @param snmp_location                   The SNMP location value
# @param snmp_package_ensure             The ensure value for SNMP
# @param snmp_ro_community               The readonly SNMP community name (required)
# @param snmp_trap_enabled               Whether the snmp trap daemon should be enabled or not
# @param snmp_trap_ensure                The ensure value for the snmp trap daemon
# @param snmp_trap_mib_dirs              An array of directories to load mibs from (if empty, `${librenms::vcs_root_dir}/mibs` will be selected)
# @param snmp_trap_mibs                  An array of mibs to load (has to be loaded in $snmp_trap_mib_dirs)
# @param snmp_varnet_group               The group used for /var/net/snmp
# @param snmp_varnet_owner               The owner used for /var/net/snmp
# @param testssl_enabled                 Whether to enable the TestSSL plugin for LibreNMS or not
# @param vcs_branch                      The LibreNMS branch to follow
# @param vcs_ensure                      The ensure value for the LibreNMS vcsrepo
# @param vcs_root_dir                    The local path to the LibreNMS installation
# @param weathermap_enabled              Whether to enable the Weathermap plugin for LibreNMS or not
#
class librenms(
  String                $config_admin_email,
  String                $mysql_librenms_password,
  String                $mysql_root_password,
  String                $snmp_ro_community,
  Array                 $snmp_trap_mib_dirs          = [],
  Array                 $snmp_trap_mibs              = ['IF-MIB'],
  Boolean               $cron_manage_service         = false,
  Boolean               $nginx_enable_mon_sites      = false,
  Boolean               $nginx_manage_repo           = false,
  Boolean               $oxidized_enabled            = false,
  Boolean               $oxidized_manage_repo        = false,
  Boolean               $php_manage_repo             = false,
  Boolean               $snmp_trap_enabled           = false,
  Boolean               $testssl_enabled             = false,
  Boolean               $weathermap_enabled          = false,
  Hash                  $config_override_pollers     = {},
  Hash                  $config_raw_input            = {},
  Hash                  $mysql_configuration         = {},
  Hash                  $oxidized_configuration      = {},
  Hash                  $php_configuration           = {},
  Integer               $config_discover_threads     = 1,
  Integer               $config_poller_threads       = 16,
  Integer               $mysql_backup_revisions      = 5,
  Integer               $nginx_fastcgi_read_timeout  = 600,
  Integer               $nginx_listen_port           = 80,
  Integer               $rrd_backup_revisions        = 0,
  Optional[Array]       $oxidized_install_packages   = undef,
  Optional[Array]       $oxidized_ruby_packages      = undef,
  Optional[String]      $import_mysqldump            = undef,
  Optional[String]      $oxidized_auth_token         = 'SetThisToYourAuthToken!',
  Optional[String]      $snmp_contact                = undef,
  Optional[String]      $snmp_varnet_group           = undef,
  Optional[String]      $snmp_varnet_owner           = undef,
  String                $librenms_group              = 'librenms',
  String                $librenms_owner              = 'librenms',
  String                $mysql_client_package_ensure = 'latest',
  String                $mysql_client_package_name   = 'mariadb-client',
  String                $mysql_librenms_username     = 'librenms',
  String                $mysql_server_package_ensure = 'latest',
  String                $mysql_server_package_name   = 'mariadb-server-10.1',
  String                $oxidized_log_path           = '/home/oxidized/.config/oxidized/log',
  String                $php_package_ensure          = 'latest',
  String                $rrdcached_pid_file          = '/run/rrdcached.pid',
  String                $rrdcached_socket_file       = '/run/rrdcached.sock',
  String                $snmp_location               = 'Unknown',
  String                $snmp_package_ensure         = 'present',
  String                $snmp_trap_ensure            = 'stopped',
  String                $vcs_branch                  = 'master',
  String                $vcs_ensure                  = 'latest',
  String                $vcs_root_dir                = '/opt/librenms',
  Variant[String,Array] $nginx_server_name           = $facts['networking']['fqdn'],

  ## PHP-FPM tuning settings
  Enum['dynamic', 'static'] $php_fpm_pm                   = 'dynamic',
  Optional[String]          $php_fpm_pm_max_children      = undef,
  Optional[String]          $php_fpm_pm_start_servers     = undef,
  Optional[String]          $php_fpm_pm_min_spare_servers = undef,
  Optional[String]          $php_fpm_pm_max_spare_servers = undef,

  ## TLS settings
  Boolean                            $nginx_ssl_enable                = false,
  Enum['on','off']                   $nginx_http2_enable              = 'on',
  Integer                            $nginx_ssl_port                  = 443,
  Optional[Boolean]                  $nginx_ssl_listen_option         = undef,
  Optional[Boolean]                  $nginx_ssl_stapling              = undef,
  Optional[Boolean]                  $nginx_ssl_stapling_verify       = undef,
  Optional[Enum['on', 'off']]        $nginx_ssl_prefer_server_ciphers = undef,
  Optional[Hash]                     $nginx_ssl_headers               = undef,
  Optional[Integer]                  $nginx_ssl_redirect_port         = undef,
  Optional[Integer]                  $nginx_ssl_verify_depth          = undef,
  Optional[String]                   $nginx_ssl_buffer_size           = undef,
  Optional[String]                   $nginx_ssl_cache                 = undef,
  Optional[String]                   $nginx_ssl_ciphers               = undef,
  Optional[String]                   $nginx_ssl_client_cert           = undef,
  Optional[String]                   $nginx_ssl_crl                   = undef,
  Optional[String]                   $nginx_ssl_dhparam               = undef,
  Optional[String]                   $nginx_ssl_ecdh_curve            = undef,
  Optional[String]                   $nginx_ssl_protocols             = undef,
  Optional[String]                   $nginx_ssl_session_ticket_key    = undef,
  Optional[String]                   $nginx_ssl_session_tickets       = undef,
  Optional[String]                   $nginx_ssl_session_timeout       = undef,
  Optional[String]                   $nginx_ssl_stapling_file         = undef,
  Optional[String]                   $nginx_ssl_stapling_responder    = undef,
  Optional[String]                   $nginx_ssl_trusted_cert          = undef,
  Optional[String]                   $nginx_ssl_verify_client         = undef,
  Optional[Variant[String, Boolean]] $nginx_ssl_cert                  = undef,
  Optional[Variant[String, Boolean]] $nginx_ssl_key                   = undef,
) {

  # Create the LibreNMS system user and group
  group { $librenms_group: }
  -> user { $librenms_owner:
    groups     => [$librenms_group, 'www-data'],
    home       => $vcs_root_dir,
    managehome => false,
    system     => true,
  }

  # Prerequisites packages
  ensure_packages([
    'composer',
    'curl',
    'fping',
    'gocr',
    'graphviz',
    'imagemagick',
    'mtr-tiny',
    'python3-pip',
    'rrdcached',
    'rrdtool',
    'snmp-mibs-downloader',
    'whois',
  ],{
    ensure => 'present'
  })

  contain librenms::librenms
  contain librenms::mysql
  contain librenms::web_services
  contain librenms::rrdcached
  contain librenms::snmp
  contain librenms::weathermap
  contain librenms::oxidized
  contain librenms::testssl
  contain librenms::cron


  Class['::librenms::librenms']
  -> Class['::librenms::mysql']
  -> Class['::librenms::web_services']
  -> Class['::librenms::rrdcached']
  -> Class['::librenms::snmp']
  -> Class['::librenms::weathermap']
  -> Class['::librenms::oxidized']
  -> Class['::librenms::testssl']
  -> Class['::librenms::cron']

  # Really make sure that the files are owned by the correct user
  file { $vcs_root_dir:
    ensure  => directory,
    recurse => true,
    owner   => $librenms_owner,
    group   => $librenms_group,
  }

  exec { 'librenms_setfacl':
    command     => @("COMMAND"/L),
      setfacl -d -m g::rwx ${vcs_root_dir}/rrd ${vcs_root_dir}/logs ${vcs_root_dir}/boostrap/cache ${vcs_root_dir}/storage && \
      setfacl -R -m g::rwx ${vcs_root_dir}/rrd ${vcs_root_dir}/logs ${vcs_root_dir}/boostrap/cache ${vcs_root_dir}/storage
      |-COMMAND
    path        => ['/usr/bin/'],
    refreshonly => true,
    subscribe   => Vcsrepo[$vcs_root_dir],
    require     => File[$vcs_root_dir],
  }

  exec { 'python3_packages':
    command     => "/usr/bin/pip3 install -r ${vcs_root_dir}/requirements.txt",
    refreshonly => true,
    subscribe   => Vcsrepo[$vcs_root_dir],
    require     => Package['python3-pip'],
  }
}
