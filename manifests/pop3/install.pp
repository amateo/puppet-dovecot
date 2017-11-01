#
class dovecot::pop3::install inherits dovecot::pop3 {
  case $facts['os']['family'] {
    'Debian': {
      if $dovecot::package_manage {
        package {$dovecot::pop3::package_name:
          ensure => $dovecot::package_ensure,
        }
      }
    }
    'RedHat': {
      # Do nothing since this is included in the core yum dovecot package
    }
  }
}
