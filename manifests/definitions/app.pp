define wordpress::app($password, $site = "$fqdn", $nginx = true, $sitedomain = "$domain") {

    ###############################
    ### VARIABLES FOR TEMPLATES ###
    ###############################

    if $nginx {
        $port = 8080
    } else {
        $port = 80
    }

    $app = $name
    $dbname = $name
    $dbuser = $name
    $dbpassword = $password


    ###################
    ### APPLICATION ###
    ###################

    user { "$app":
        ensure     => present,
        gid        => 'www-data',
        managehome => true,
        require    => Package['apache2'],
    }

    file { "/home/$app":
        ensure  => directory,
        owner   => "$app",
        group   => 'www-data',
        mode    => 755,
        require => User["$app"],
    }

    file { "/home/$app/shared":
        ensure  => directory,
        owner   => "$app",
        group   => 'www-data',
        mode    => 775,
        require => [ User["$app"], File["/home/$app"], ],
    }

    file { "/home/$app/shared/uploads":
        ensure  => directory,
        owner   => "$app",
        group   => 'www-data',
        mode    => 2775,  # SGID
        require => [ User["$app"], File["/home/$app/shared"], ],
    }

    file { "/home/$app/releases":
        ensure  => directory,
        owner   => "$app",
        group   => 'www-data',
        mode    => 775,
        require => [ User["$app"], File["/home/$app"], ],
    }

    file { "/home/$app/shared/wp-config.php":
        ensure  => present,
        owner   => "$app",
        group   => 'www-data',
        mode    => 775,
        content => template('wordpress/wp-config.php.erb'),
        require => [ User["$app"], File["/home/$app/shared"], ],
    }


    ##################
    ### WEB SERVER ###
    ##################

    file { '/etc/apache2/ports.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => 644,
        content => template('wordpress/ports.conf.erb'),
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    file { "/etc/apache2/sites-available/default":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => 644,
        content => template('wordpress/apache.erb'),
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    if $nginx {
        package { 'nginx': ensure => installed, }
        service { 'nginx':
            ensure  => running,
            enable  => true,
            require => Package['nginx'],
        }
        file { "/etc/nginx/sites-available/default":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => 644,
            content => template('wordpress/nginx.erb'),
            require => Package['nginx'],
            notify  => Service['nginx'],
        }
    }


    ################
    ### DATABASE ###
    ################

    if $mysql_exists == 'true' {
        mysql_database { "$dbname":
            ensure => present,
        }

        # This creates the user if not defined elsewhere
        mysql::rights{ "Wordpress database (localhost access)":
          ensure   => present,
          database => "$dbname",
          user     => "$dbuser",
          password => "$dbpassword",
        }

        # Database used for db update
        mysql::rights{ "WIP database used to compare schemas for db update":
          ensure   => present,
          database => "wip",
          user     => "$dbuser",
          password => "$dbpassword",
        }
    }
}

# vim: set ts=4 sw=4 et:
