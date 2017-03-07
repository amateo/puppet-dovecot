# 10-auth.conf
# See README.md for usage
class dovecot::auth (
  Hash[String, Optional[String]] $options,
  Hash[String, Hash] $unix_listeners,
  Array[Hash] $passdb,
  Array[Hash] $userdb,
  Hash $ldapfile,
  Hash $passwdfile,
) inherits dovecot {
  dovecot::config::dovecotcfhash {'auth':
    config_file => 'conf.d/10-auth.conf',
    options     => $options,
  }

  dovecot::master::service {'auth':
    ensure  => 'present',
  }

  # Configure unix_listeners included in $unix_listeners
  $unix_listeners.each |String $k, Hash $opt| {
    dovecot::auth::unix_listener {$k:
      * => $opt,
    }
  }

  $default_database = 'auth-databases.conf.ext'
  concat {"/etc/dovecot/conf.d/${default_database}":
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    ensure_newline => true,
  }

  range(0,size($passdb)-1).each |$k| {
    $order = 50+$k
    $opts = $passdb[$k]

    case $opts['driver'] {
      'ldap': {
        $require = [
          Class['dovecot::ldap'],
          Dovecot::Auth::Ldapfile[$opts['args']],
        ]
      }
      # TODO: Programar un require del passwd-file, pero como puede
      # haber más de un argumento...
      'passwd-file': { }
      'pam': { }
      'static': { }
      default: {
        fail("Driver ${opts['driver']} not supported")
      }
    }
    dovecot::auth::passdb {"${order}":
      order   => "${order}",
      require => $require,
      *       => $opts,
    }
  }

  range(0,size($userdb)-1).each |$k| {
    $order = 70+$k
    $opts = $userdb[$k]

    case $opts['driver'] {
      'ldap': {
        $require = [
          Class['dovecot::ldap'],
          Dovecot::Auth::Ldapfile[$opts['args']],
        ]
      }
      /static|prefetch/: { }
      default: {
        fail("Driver ${opts['driver']} not supported")
      }
    }
    dovecot::auth::userdb {"${order}":
      order   => "${order}",
      require => $require,
      *       => $opts,
    }
  }

  dovecot::config::dovecotcfmulti {'Add default auth':
    config_file => 'conf.d/10-auth.conf',
    onlyif      => "values include not_include ${default_database}",
    changes     => [ "set include[last()+1] ${default_database}" ],
    require     => [
      Concat["/etc/dovecot/conf.d/${default_database}"],
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
}

