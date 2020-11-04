# @summary Manages the cron service
#
# Manages the cron service
#
# @example
#   use main class
class librenms::cron {
  if $librenms::cron_manage_service {
    service { 'cron':
      ensure => running,
      enable => true,
    }
  }
}
