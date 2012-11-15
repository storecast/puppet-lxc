module Puppet::Parser::Functions
  require 'digest/md5'
  newfunction(:lxc_genmac, :type => :rvalue) do |args|
      macpref = "00:ff:11" #args[1] #some mac-prefix
      md5 = Digest::MD5.hexdigest(args[0])
      #"00:FF:11:11:01:01"
      return "#{macpref}:#{md5[0,2]}:#{md5[2,2]}:#{md5[4,2]}"
  end
end