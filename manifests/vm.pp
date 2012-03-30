# defined container from host 
define lxc::vm ($ip = "dhcp",
	$mac,
	$netmask = "255.255.255.0",
	$passwd = "foobar",
	$distrib = "squeeze",
	$ensure = "present") {
	File {
		ensure => $ensure,
	}
	file {
		"/var/lib/lxc/${name}" :
			ensure => $ensure ? {
				"present" => "directory",
				default => "absent"
			} ;

		"/var/lib/lxc/${name}/preseed.cfg" :
			owner => "root",
			group => "root",
			mode => 0644,
			content => template("lxc/preseed.cfg.erb") ;

		"/var/lib/lxc/${name}/rootfs/etc/network/interfaces" :
			owner => "root",
			group => "root",
			mode => 0644,
			require => Exec["create ${name} container"],
			subscribe => Exec["create ${name} container"],
			content => template("lxc/interface.erb") ;
	}
	if $ensure == "present" {
		exec {
			"create ${name} container" :
				command =>
				"${lxc::mdir}/templates/lxc-debian --preseed-file=/var/lib/lxc/${name}/preseed.cfg -p /var/lib/lxc/${name} -n ${name}",
				require => File["/var/lib/lxc/${name}/preseed.cfg"],
				refreshonly => false,
				creates => "/var/lib/lxc/${name}/config"
		}
	}
}

