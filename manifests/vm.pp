# defined container from host
define lxc::vm ($ip = "dhcp",
	$mac,
	$netmask = "255.255.255.0",
	$passwd,
	$distrib = "squeeze",
	$container_root = "/var/lib/lxc",
	$ensure = "present",
	$mainuser = '',
	$mainuser_sshkey = '',
	$autorun = true,
	$autostart = true) {
	require 'lxc::controlling_host' File {
		ensure => $ensure,
	}
	$c_path = "${container_root}/${name}"
	$h_name = $name
	file {
		"${c_path}" :
			ensure => $ensure ? {
				"present" => "directory",
				default => "absent"
			} ;

		"${c_path}/preseed.cfg" :
			owner => "root",
			group => "root",
			mode => 0644,
			content => template("lxc/preseed.cfg.erb") ;

		"${c_path}/rootfs/etc/network/interfaces" :
			owner => "root",
			group => "root",
			mode => 0644,
			require => Exec["create ${h_name} container"],
			subscribe => Exec["create ${h_name} container"],
			content => template("lxc/interface.erb") ;
	}
	if defined(Class["dnsmasq"]) {
		dnsmasq::dhcp-host {
			"${h_name}-${mac}" :
				hostname => $name,
				mac => $mac,
		}
	}
	if $ensure == "present" {
		exec {
			"create ${h_name} container" :
				command =>
				#"${lxc::mdir}/templates/lxc-debian --preseed-file=/var/lib/lxc/${h_name}/preseed.cfg -p /var/lib/lxc/${h_name} -n ${h_name}",
				"/bin/bash ${lxc::mdir}/templates/lxc-debian -p ${c_path} -n ${h_name}",
				require => File["${c_path}/preseed.cfg"],
				refreshonly => false,
				creates => "${c_path}/config",
				logoutput => true,
		}
		Line {
			require => Exec["create ${h_name} container"],
			file => "${c_path}/config",
		}
		Replace {
			require => Exec["create ${h_name} container"],
		}
		line {
			"mac: ${mac}" :
				line => "lxc.network.hwaddr = ${mac}" ;

			"bridge: {${mac}:${lxc::controlling_host::bridge}" :
				line => "lxc.network.link = ${lxc::controlling_host::bridge}" ;

			"send host-name \"${h_name}\";" :
				file => "${c_path}/rootfs/etc/dhcp/dhclient.conf" ;
		}
		exec {
			"etc_hostname: ${h_name}" :
				command => "echo ${h_name} > ${c_path}/rootfs/etc/hostname",
				subscribe => Exec["create ${h_name} container"],
				refreshonly => true,
		}
		## setting the root-pw
		#echo "root:root" | chroot $rootfs chpasswd
		exec {
			"set_rootpw: ${h_name}" :
				command => "echo \"root:${passwd}\" | chroot ${c_path}/rootfs chpasswd",
				refreshonly => true,
				require => Exec["create ${h_name} container"],
				subscribe => Exec["create ${h_name} container"],
		}
		## Disable root - login via ssh
		replace {
			"sshd_noRootlogin: ${h_name}" :
				file => "${c_path}/rootfs/etc/ssh/sshd_config",
				pattern => "PermitRootLogin yes",
				replacement => "PermitRootLogin no",
		}
		if $mainuser != '' and $mainuser_sshkey != '' {
			exec {
				"${h_name}::useradd_${mainuser}" :
					command =>
					"chroot ${c_path}/rootfs useradd -s /bin/bash -g users -G adm -c \"Admin user\" ${mainuser}",
					subscribe => Exec["create ${h_name} container"],
					refreshonly => true,
			}
			line {
				"${h_name}::mongrify_sudoers" :
					line => "%adm ALL=(ALL) NOPASSWD: ALL",
					file => "${c_path}/rootfs/etc/sudoers",
					require => Exec["${h_name}::useradd_${mainuser}"],
			}
			## create ssh dir for user
			$ssh_dir = "${c_path}/rootfs/home/${mainuser}/.ssh"
			exec {
				"${h_name}::sshkey_${mainuser}" :
					command =>
					"mkdir -p ${ssh_dir} && echo \"${mainuser_sshkey}\" > ${ssh_dir}/authorized_keys && chroot ${c_path}/rootfs chown -R ${mainuser}:users /home/${mainuser}",
					subscribe => Exec["${h_name}::useradd_${mainuser}"],
					unless => "test -e ${ssh_dir}/.ssh/authorized_keys",
					refreshonly => true,
			}
			exec {
				"${h_name}::install-puppet" :
					command =>
					"sed -i -e 's/exit\ 0//' ${c_path}/rootfs/etc/rc.local && echo 'apt-get -y update && apt-get  -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" -y install facter puppet' >>${c_path}/rootfs/etc/rc.local",
					subscribe => Exec["create ${h_name} container"],
					refreshonly => true,
			}
		}
		if $autostart {
			exec {
				"/usr/bin/lxc-start -n ${h_name} -d" :
					onlyif => "/usr/bin/lxc-info -n ${h_name} 2>/dev/null | grep -q STOPPED",
					require => [Exec["create ${h_name} container"],
					Exec["${h_name}::install-puppet"]],
			}
		}
	} #end ensure=present
	file {
		"/etc/lxc/auto/${h_name}.conf" :
			target => "/var/lib/lxc/${h_name}/config",
			ensure => $autorun ? {
				true => "present",
				false => "absent",
			}
	}
}

