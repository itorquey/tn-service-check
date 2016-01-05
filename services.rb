require 'json'
require 'open-uri'
require 'socket'


module TribesNext
	class Services
		# Read service definitions from a coniguration file
		def self.read_config(config_file)
			contents = File.read(config_file)
			services = JSON.parse(contents)
			return services
		end


		# Write service definitions to configuration file
		def self.write_config(config_file, services)
			contents = JSON.pretty_generate(services)
			File.write(config_file, contents)
		end


		# Query a service
		def self.query_service(service)
			url = service['url']
			available = case service['type']
				when 'auth' then AccountService.query(url)
				when 'list' then ListService.query(url)
				when 'community' then CommunityService.query(url)
				else false
			end
			changed = (available != service['available'])

			service['changed'] = changed
			service['available'] = available
			return [available, changed]
		end
	end


	class ServiceBase
		# Query an HTTP service
		def self.query_http_service(url)
			begin
				# Fetch details over HTTP
				url = URI.parse(url)
				info = url.read
				# Assume online if we get a 200/OK response
				return '200' === info.status[0]
			rescue
				return false
			end
		end
	end


	class AccountService < ServiceBase
		# Query the account service to determine its status
		def self.query(url)
			begin
				# Discover host
				auth_host, auth_port = discover(url)
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
			rescue
				return false
			end
		end


		# Discover the account service host/port
		def self.discover(url)
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


	class ListService < ServiceBase
		# Query the listing service to determine its status
		def self.query(url)
			return query_http_service(url)
		end
	end


	class CommunityService < ServiceBase
		# Query the community service to determine its status
		def self.query(url)
			return query_http_service(url)
		end
	end
end