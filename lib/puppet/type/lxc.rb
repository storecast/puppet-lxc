module Puppet
	newtype(:lxc) do
		@doc = "Manages Linux Container. Create a new lxc."

		# A base class for numeric Lxc parameters validation.
		class VirtNumericParam < Puppet::Parameter

			def numfix(num)
				if num =~ /^\d+$/
					return num.to_i
				elsif num.is_a?(Integer)
					return num
				else
					return false
				end
			end

			validate do |value|
				if numfix(value)
					return value
				else
					self.fail "%s is not a valid %s" % [value, self.class.name]
				end
			end

		end

		def self.instances()
			[]
		end

		ensurable do
			desc "The container's ensure field can assume one of the following values:
	`running`:
		Creates config file, and makes sure the container is running.
	`installed`:
		Creates config file, but doesn't touch the state of the container.
	`stopped`:
		Creates config file, and makes sure the container is not running.
	`absent`:
		Removes config file, and makes sure the container is not running."
		
			newvalue(:stopped) do
				provider.stop
			end
	
			newvalue(:running) do
				provider.start
			end

			newvalue(:installed) do
				provider.setpresent
			end

			newvalue(:absent) do
				provider.destroy
			end

			defaultto(:running)
			
			def retrieve
				provider.status
			end
	
		end
		
		newparam(:desc) do
			desc "The container's description."
		end
	
		newparam(:name, :namevar => true) do
			desc "The container's name."
		end

		# This will change to properties
		newparam(:cpus, :parent => VirtNumericParam) do
			desc "Number of virtual CPUs active in the container container."

			defaultto(1)
		end
	
		#Kickstart file location on the network
		newparam(:kickstart) do
			desc "Kickstart file location. "
			
			munge do |value|
				"ks=" + value
			end	
		
		end

		# Disk size (only used for creating new containers
		newparam(:disk_size, :parent => VirtNumericParam) do
			desc "Size (in GB) to use if creating new container storage. Not changeable."

			munge do |value|
				"size=" + value
			end

		end

		newparam(:interfaces) do
			desc " Connect the container network to the host using the specified network as a bridge. The value can take one of 2 formats:
	`disable`:
		The container will have no network.
	`[ \"ethX\", ... ] | \"ethX\" `
		The container can receive one or an array with interface's name from host to connect to the container interfaces.
	If the specified interfaces does not exist, it will be ignored and raises a warning."

			validate do |value|
				unless value.is_a?(Array) or value.is_a?(String)
					self.devfail "interfaces field must be a String or an Array"
				end
			end
		end

		newparam(:macaddrs) do
			desc "Fixed MAC address for the container; 
If this parameter is omitted, or the value \"RANDOM\" is specified a suitable address will be randomly generated."
		end
	end
end
