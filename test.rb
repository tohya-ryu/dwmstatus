require 'resolv'

dns_resolver = Resolv::DNS.new
dns_resolver.timeouts = 0.5
dns_resolver.getaddress("tohya.net")

