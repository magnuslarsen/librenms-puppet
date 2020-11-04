# @summary Manages all MySQL resources
#
# Manages all MySQL resources
#
# @example
#   use main class
class librenms::mysql {
  $sane_default = {
    'bind-address'                   => '*',
    'innodb_data_file_path'          => 'innodata0:512M:autoextend',
    'innodb_data_home_dir'           => '/var/lib/mysql/innodb_data',
    'innodb_flush_log_at_trx_commit' => '0',
    'innodb_log_buffer_size'         => '128M',
    'innodb_log_file_size'           => '1024M',
    'innodb_log_group_home_dir'      => '/var/lib/mysql/innodb_log',
    'innodb_thread_concurrency'      => '0',
    'innodb_file_per_table'          => '1',
    'log-queries-not-using-indexes'  => true,
    'skip-external-locking'          => true,
    'tmpdir'                         => '/var/lib/mysqltmp',
  }

  $mysqld = deep_merge($sane_default, $librenms::mysql_configuration)

  class { 'mysql::server':
    package_name            => $librenms::mysql_server_package_name,
    package_ensure          => $librenms::mysql_server_package_ensure,
    root_password           => $librenms::mysql_root_password,
    remove_default_accounts => true,
    override_options        => {
      mysqld => $mysqld,
    },
  }

  class { 'mysql::client':
    package_name   => $librenms::mysql_client_package_name,
    package_ensure => $librenms::mysql_client_package_ensure,
  }

  # Import SQL if path is specified
  if $librenms::import_mysqldump {
    $_sql = $librenms::import_mysqldump
    $_enforce_sql = true
  }
  else {
    $_sql = undef
    $_enforce_sql = undef
  }

  mysql::db { 'librenms':
    user           => $librenms::mysql_librenms_username,
    password       => $librenms::mysql_librenms_password,
    host           => 'localhost',
    grant          => ['ALL'],
    collate        => 'utf8_unicode_ci',
    charset        => 'utf8',
    sql            => $_sql,
    enforce_sql    => $_enforce_sql,
    require        => Class['::mysql::client'],
    import_timeout => 0,
  }

  ## BACKUP ##
  class { 'mysql::server::backup':
    backupuser        => $librenms::mysql_librenms_username,
    backuppassword    => $librenms::mysql_librenms_password,
    backupdirowner    => $librenms::librenms_owner,
    backupdirgroup    => $librenms::librenms_group,
    backupdir         => "${librenms::vcs_root_dir}/backup/",
    backupdirmode     => '0644',
    maxallowedpacket  => '128M',
    file_per_database => true,
    time              =>  ['01', '30'], # 01:30 (AM)
    backuprotate      => $librenms::mysql_backup_revisions,
  }
}
