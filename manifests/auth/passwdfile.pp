#
# See README.md for usage
define dovecot::auth::passwdfile (
  String $owner             = 'root',
  String $group             = 'dovecot',
  String $mode              = '0640',
  Optional[String] $source  = undef,
  Optional[String] $content = undef,
  Array[String] $users      = [],
) {
  include ::dovecot::ldap

  $manage_content = $source ? {
    undef     => $content ? {
      undef   => epp('dovecot/auth/passwd-file.epp', { users => $users }),
      default => $content,
    },
    default => undef,
  }

  file {$name:
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    source  => $source,
    content => $manage_content,
  }
}
