#
class dovecot::lmtp::install inherits dovecot::lmtp {
  case $facts['os']['family'] {
    'Debian': {
      if $dovecot::package_manage {
        package {$dovecot::lmtp::package_name:
          ensure => $dovecot::package_ensure,
        }
      }
    }
    'RedHat': {
      # Do nothing since this is included in the core yum dovecot package
    }
  }
}
