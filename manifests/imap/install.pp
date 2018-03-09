#
class dovecot::imap::install inherits dovecot::imap {
  case $facts['os']['family'] {
    'Debian': {
      if $dovecot::package_manage {
        package {$dovecot::imap::package_name:
          ensure => $dovecot::package_ensure,
        }
      }
    }
    'RedHat': {
      # Do nothing since this is included in the core yum dovecot package
    }
  }
}
