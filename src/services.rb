require 'json'
require 'open-uri'
require 'socket'


module TribesNext
	# Read service definitions from a coniguration file
	def read_config(config_file)
		contents = File.read(config_file)
		services = JSON.parse(contents)
		return services
	end


	# Write service definitions to configuration file
	def write_config(config_file, services)
		contents = JSON.pretty_generate(services)
		File.write(config_file, contents)
	end


	# Query a service
	def query_service(service)
		url = service['url']
		available? = case service['type']
			when 'auth' then TribesNext.Account.query(url)
			when 'list' then TribesNext.Listing.query(url)
			when 'community' then TribesNext.Community.query(url)
			else false
		end
		changed? = (available? != service['available'])


		service['changed'] = changed?
		service['available'] = available?
		return [available? changed?]
	end


	# Query an HTTP service
	def query_http_service(url)
		# Fetch details over HTTP
		url = URI.parse(url)
		info = url.read
		# Assume online if we get a 200/OK response
		return '200' === info.status[0]
	end


	module Account
		# Query the account service to determine its status
		def query(url)
			# Discover host
			auth_host, auth_port = discover(service)
			unless auth_host.nil? then
				# Query host
				sock = TCPSocket.new auth_host, auth_port
				sock.puts 'AVAIL'
				status = sock.gets
				sock.close

				return 'AVAIL' === status.strip
			else
				return false
			end
		end


		# Discover the account service host/port
		def discover(url)
			# Fetch details over HTTP
			url = URI.parse(url)
			info = url.read
			# Parse out host:port
			if '200' === info.status[0] then
				info.split(/[:\s]/)
			else
				return nil
			end
		end
	end


	module Listing
		# Query the listing service to determine its status
		def query(url)
			return TribesNext.query_http(url)
		end
	end


	module Community
		# Query the community service to determine its status
		def query(url)
			return TribesNext.query_http(url)
		end
	end
end
