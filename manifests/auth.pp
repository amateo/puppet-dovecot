# 10-auth.conf
# See README.md for usage
class dovecot::auth (
  Hash[String, Optional[String]] $options,
  Hash[String, Hash] $unix_listeners,
  Hash[String, Optional[Variant[String,Integer]]] $service_options,
  Variant[Array[Hash],Hash] $passdb,
  Variant[Array[Hash],Hash] $userdb,
  Hash $ldapfile,
  Hash $passwdfile,
  Hash $sqlfile,
) inherits dovecot {
  dovecot::config::dovecotcfhash {'auth':
    config_file => 'conf.d/10-auth.conf',
    options     => $options,
  }

  dovecot::master::service {'auth':
    ensure  => 'present',
    options => $service_options,
  }

  # Configure unix_listeners included in $unix_listeners
  $unix_listeners.each |String $k, Hash $opt| {
    dovecot::auth::unix_listener {$k:
      * => $opt,
    }
  }

  $default_database = 'auth-databases.conf.ext'
  concat {"${dovecot::config_dir}/conf.d/${default_database}":
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    ensure_newline => true,
  }

  if $passdb =~ Array[Hash] {
    range(0,size($passdb)-1).each |$k| {
      $order = sprintf('%d', 50+$k)
      $opts = $passdb[$k]

      case $opts['driver'] {
        'ldap': {
          $require = [
            Class['dovecot::ldap'],
            Dovecot::Auth::Ldapfile[$opts['args']],
          ]
        }
        # TODO: Programar un require del passwd-file, pero como puede
        # haber mas de un argumento...
        'passwd-file': {
          $require = undef
        }
        'pam': {
          $require = undef
        }
        'sql': {
          $require = Dovecot::Auth::Sqlfile[$opts['args']]
        }
        'static': {
          $require = undef
        }
        default: {
          fail("Driver ${opts['driver']} not supported")
        }
      }
      dovecot::auth::passdb {$order:
        order   => $order,
        require => $require,
        *       => $opts,
      }
    }
  } else {
    $passdb_keys = keys($passdb)
    range(0,size($passdb_keys)-1).each |$k| {
      $order = sprintf('%d', 50+$k)
      $opts = $passdb[$passdb_keys[$k]]

      case $opts['driver'] {
        'ldap': {
          $require = [
            Class['dovecot::ldap'],
            Dovecot::Auth::Ldapfile[$opts['args']],
          ]
        }
        # TODO: Programar un require del passwd-file, pero como puede
        # haber mas de un argumento...
        'passwd-file': {
          $require = undef
        }
        'pam': {
          $require = undef
        }
        'sql': {
          $require = Dovecot::Auth::Sqlfile[$opts['args']]
        }
        'static': {
          $require = undef
        }
        default: {
          fail("Driver ${opts['driver']} not supported")
        }
      }
      dovecot::auth::passdb {$order:
        order   => $order,
        require => $require,
        *       => $opts,
      }
    }
  }

  if $userdb =~ Array[Hash] {
    range(0,size($userdb)-1).each |$k| {
      $order = sprintf('%d', 70+$k)
      $opts = $userdb[$k]

      case $opts['driver'] {
        'passwd': {
          $require = undef
        }
        'passwd-file': {
          $require = undef
        }
        'ldap': {
          $require = [
            Class['dovecot::ldap'],
            Dovecot::Auth::Ldapfile[$opts['args']],
          ]
        }
        /static|prefetch/: {
          $require = undef
        }
        'sql': {
          $require = Dovecot::Auth::Sqlfile[$opts['args']]
        }
        default: {
          fail("Driver ${opts['driver']} not supported")
        }
      }
      dovecot::auth::userdb {$order:
        order   => $order,
        require => $require,
        *       => $opts,
      }
    }
  } else {
    $userdb_keys = keys($userdb)
    range(0,size($userdb_keys)-1).each |$k| {
      $order = sprintf('%d', 70+$k)
      $opts = $userdb[$userdb_keys[$k]]

      case $opts['driver'] {
        'passwd-file': {
          $require = undef
        }
        'ldap': {
          $require = [
            Class['dovecot::ldap'],
            Dovecot::Auth::Ldapfile[$opts['args']],
          ]
        }
        /static|prefetch/: {
          $require = undef
        }
        'sql': {
          $require = Dovecot::Auth::Sqlfile[$opts['args']]
        }
        default: {
          fail("Driver ${opts['driver']} not supported")
        }
      }
      dovecot::auth::userdb {$order:
        order   => $order,
        require => $require,
        *       => $opts,
      }
    }
  }

  dovecot::config::dovecotcfmulti {'Remove default system auth':
    config_file => 'conf.d/10-auth.conf',
    onlyif      => 'values include include auth-system.conf.ext',
    changes     => [ "rm include[ . = \"auth-system.conf.ext\" ]" ],
  }

  dovecot::config::dovecotcfmulti {'Add default auth':
    config_file => 'conf.d/10-auth.conf',
    onlyif      => "values include not_include ${default_database}",
    changes     => [ "set include[last()+1] ${default_database}" ],
    require     => [
      Concat["${dovecot::config_dir}/conf.d/${default_database}"],
      Dovecot::Config::Dovecotcfhash['auth'],
    ],
  }

  $ldapfile.each |$name, $opts| {
    dovecot::auth::ldapfile {$name:
      * => $opts,
    }
  }

  $passwdfile.each |$name, $opts| {
    dovecot::auth::passwdfile {$name:
      * => $opts,
    }
  }

  $sqlfile.each |$name, $opts| {
    dovecot::auth::sqlfile {$name:
      * => $opts,
    }
  }
}

