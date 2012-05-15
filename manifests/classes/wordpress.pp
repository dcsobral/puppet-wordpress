class wordpress {
    package { 'wordpress': ensure => installed, }
    include git
    include apache
    include apache::enable-mod-rewrite
    include apache::enable-mod-deflate
    include mysql::server
}

# vim: set ts=4 sw=4 et:
