- [Overview](#overview)
  - [Fresh installation](#fresh-installation)
  - [Database](#database)
    - [Importing an old database (or a backup)](#importing-an-old-database-or-a-backup)
    - [Database backups](#database-backups)
    - [Updating database username / password](#updating-database-username--password)
  - [Main configuration file (config.php)](#main-configuration-file-configphp)
  - [NGINX and PHP-FPM monitoring](#nginx-and-php-fpm-monitoring)
  - [LibreNMS plugins](#librenms-plugins)
    - [Weathermap](#weathermap)
    - [Oxidized](#oxidized)
    - [TestSSL](#testssl)
  - [SNMP traps](#snmp-traps)
- [Sample setup](#sample-setup)

# Overview
This module will install and manage LibreNMS, NGINX, PHP + PHP-FPM, RRD + RRDCached, MySQL (MariaDB), SNMP, on a single machine (optionally: Cron, Oxidized and LibreNMS plugins).

This module acts as a "meta module", as it depends heavily on other modules in order to tie everything together.

This module has been tested on a Debian based OS (Ubuntu 18.04.x), but should work on RHEL based OS'es with minor tweaking.

## Fresh installation
NOTE: If you have a backup file, you can [import that instead](#importing-an-old-database-or-a-backup)

Since this module creates and manages the appropiate database, and a fresh LibreNMS installation doesn't like that, you have to drop the database first, before you can continue on the installation page:
1. `mysql -u root -p -e 'DROP DATABASE librenms;'`
2. Go to `http://librenms.example.com/install.php`

## Database
### Importing an old database (or a backup)
If you have a previous mysqldump of a LibreNMS installation, you can import it using the `$import_mysqldump` parameter:
1. Copy the MySQL dump onto the new LibreNMS server, and place it somewhere (e.g. `/tmp/librenms_dump.sql`)
2. In Puppet, specify `import_mysqldump => '/tmp/librenms_dump.sql'`
3. Delete the current database (resolves database version mismatch), run `mysql -u root -p -e 'DROP DATABASE librenms;'`
4. Run Puppet
5. Migrate the database to newest version, run `/opt/librenms/lnms migrate`
6. Remove the `$import_mysqldump` parameter again, to not re-import the dump

### Database backups
A backup (mysqldump) of the LibreNMS database will be taken automatically, everyday at 01:30 (AM).

The number of revisions to keep on disk, can be controlled by the `$mysql_backup_revisions` parameter.

Backups are placed here: `${librenms::vcs_root_dir}/backup/`

### Updating database username / password
When updating database username or -password, this module will do most of the legwork.

However, LibreNMS keeps "temporary" settings in a environment file, found at `${librenms::vcs_root_dir}/.env`, including the database username and -password. You have to manually update this file!

## Main configuration file (config.php)
The main LibreNMS configuration file can be managed with Puppet, using the `$config_raw_input` parameter. This parameter will be converted to `config.php` viable code, using a very basic built-in parser (`lib/puppet/functions/to_phpconfig.rb`)

All nested configuration options can be specified in Puppet with a dot (`.`), example: `auth_ad_groups.LibreNMS_Admins.level` (Puppet) turns into `$config['auth_ad_groups']['LibreNMS_Admins']['level']` (config.php)

Strings, Booleans, Integers, Floats, Hashes, Arrays, and Array of Hashes are supported by the built-in parser.

## NGINX and PHP-FPM monitoring
If `$nginx_enable_mon_sites` is set to `true`, monitoring pages will be enabled.

These pages can be queried using the following commands:
```bash
# Can only be done locally from the server
curl "localhost:8080/nginx_status"
curl "localhost:8080/fpm-status"
curl "localhost:8080/fpm-ping"
```

## LibreNMS plugins
The following plugins can be installed using Puppet, but has to be enabled manually in the LibreNMS web-interface.

### Weathermap
The Weathermap plugin can be installed by setting the `$weathermap_enabled` to `true`.

### Oxidized
The Oxidized plugin can be installed by setting the `$oxidized_enabled` parameter to `true`.

Oxidized can be futher customized by setting the `$oxidized_configuration` parameter, and the oxidized specific settings in `$config_raw_input`.

### TestSSL
A basic TestSSL plugin is included in this Puppet module, and can be installed by setting the `$testssl_enabled` to `true`.

The TestSSL plugin runs [TestSSL](https://testssl.sh/), and displays the output directly in LibreNMS.

## SNMP traps
NOTE: SNMP traps are a [in-progress feature in LibreNMS](https://github.com/librenms/librenms/tree/master/LibreNMS/Snmptrap/Handlers). Support may be very varied!

This module can configure SNMP traps for LibreNMS. You simply add this configuration:
```puppet
class { '::librenms':
  snmp_trap_enabled  => true,
  snmp_trap_ensure   => running,
  config_raw_input   => {
    'snmptraps.eventlog' => 'all',
  }
  snmp_trap_mib_dirs => [
    '/opt/librenms/mibs',
    '/opt/librenms/mibs/cisco',
    '/opt/librenms/mibs/hp',
    '/opt/librenms/mibs/paloaltonetworks',
  ],
  snmp_trap_mibs    => ['ALL'],
}
```

For `$snmp_trap_mib_dirs` and `$snmp_trap_mibs` it is recommended to specify which MIBs to use, and not `all`. \
A full list can be found in [the LibreNMS github repository](https://github.com/librenms/librenms/tree/master/mibs).

# Sample setup
```puppet
# LibreNMS with Oxidized + Weathermap plugins, active Netscaler poller, AD logins, and sample TLS config
class { '::librenms':
  config_admin_email              => $admin_email,
  config_poller_threads           => 32,
  mysql_librenms_password         => $mysql_librenms_password,
  mysql_root_password             => $mysql_root_password,
  oxidized_auth_token             => $oxidized_api_token,
  oxidized_enabled                => true,
  oxidized_manage_repo            => true,
  snmp_location                   => 'Null Island',
  snmp_ro_community               => $snmp_ro_community,
  weathermap_enabled              => true,
  config_override_pollers         => {
    'netscaler-vsvr' => 1,
  },
  config_raw_input                => {
    'active_directory.users_purge'         => 14, # days
    'auth_ad_base_dn'                      => 'DC=domain,DC=com',
    'auth_ad_bindpassword'                 => $ad_bind_password,
    'auth_ad_binduser'                     => $ad_bind_username,
    'auth_ad_check_certificates'           => 0,
    'auth_ad_domain'                       => 'domain.com',
    'auth_ad_groups.LibreNMS_Admins.level' => 10,
    'auth_ad_groups.LibreNMS_Users.level'  => 5,
    'auth_ad_require_groupmembership'      => 1,
    'auth_ad_url'                          => 'ldaps://domain.com',
    'auth_mechanism'                       => 'active_directory',
    'authlog_purge'                        => 15, # days
    'oxidized.enabled'                     => true,
    'oxidized.url'                         => 'http://127.0.0.1:8888',
    'oxidized.group_support'               => true,
    'oxidized.features.versioning'         => true,
    'oxidized.reload_nodes'                => false,
    'oxidized.group.os'                    => [
      { 'match' => 'asa',       'group' => 'cisco-asa-device' },
      { 'match' => 'ios',       'group' => 'cisco-device' },
      { 'match' => 'iosxe',     'group' => 'cisco-device' },
      { 'match' => 'netscaler', 'group' => 'netscaler-device' },
      { 'match' => 'procurve',  'group' => 'procurve-device' },
    ],
    'oxidized.group.hostname'              => [
      { 'regex' => '/^switch\d.*/', 'group' => 'switches' },
      { 'regex' => '/^router\d.*/', 'group' => 'routers' },
    ],
  }
  # TLS settings are primary taken from these:
  # https://ssl-config.mozilla.org/#server=nginx&config=intermediate&ocsp=false
  # https://cipherli.st/
  nginx_ssl_enable                => true,
  nginx_ssl_protocols             => 'TLSv1.2 TLSv1.3',
  nginx_ssl_ciphers               => 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384', #lint:ignore:140chars
  nginx_ssl_cert                  => "${cert_root_path}/full_cert.pem",
  nginx_ssl_key                   => "${cert_root_path}/cert.key",
  nginx_ssl_prefer_server_ciphers => 'on',
  nginx_ssl_cache                 => 'shared:ssl_cache:10m',
  nginx_ssl_session_tickets       => 'off',
  nginx_ssl_session_timeout       => '1d',
  nginx_ssl_dhparam               => "${cert_root_path}/dhparam.pem",
  nginx_ssl_headers               => {
    'Strict-Transport-Security' => 'max-age=31557600',
    'X-Frame-Options'           => 'DENY',
    'X-Content-Type-Options'    => 'nosniff',
    'X-XSS-Protection'          => '1; mode=block',
  },
  oxidized_configuration          => {
    'groups'    => $oxidized_config_groups,
    'input'     => {
      'ssh' => {
        'secure' => false, # Disable hostkey verification
      },
    },
    'model_map' => {
      'procurve'   => 'procurve',
      'cisco'      => 'ios',
      'asa'        => 'asa',
      'ciscowlc'   => 'aireos',
      'arista'     => 'eos'
    },
  },
}
```
