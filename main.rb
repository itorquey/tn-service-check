require 'twitter'
require './services.rb'


class ServiceQuery
	# Path to service definition file
	SERVICE_CONFIG = './conf/services.json'

	# Path to twitter configuration file
	TWITTER_CONFIG = './conf/twitter.json'


	# Query services and post any updates to twitter
	def self.run
		# Load configuration
		twitter_client = get_twitter_client
		service_defs = load_service_defs

		# Query services
		query_services(twitter_client, service_defs)

		# Save configuration
		write_service_defs(service_defs)
	end


	# Load service definitions
	def self.load_service_defs
		TribesNext::Services.read_config(SERVICE_CONFIG)
	end


	# Save service definitions
	def self.write_service_defs(service_defs)
		TribesNext::Services.write_config(SERVICE_CONFIG, service_defs)
	end


	# Query services, and post updates if any have changed availability
	def self.query_services(twitter_client, service_defs)
		workers = []

		# Create background worker for each service
		service_defs.each { |s|
			workers << Thread.new(s) {|x| query_service(twitter_client, x)}
		}
		# Wait for updates to complete
		workers.each {|w| w.join }

		return service_defs
	end


	# Query a service, and post an update if it has changed availability
	def self.query_service(twitter_client, service_def)
		begin
			is_plural = ('s' === service_def['name'])
			is_available, is_changed = TribesNext::Services.query_service(service_def)

			# if state changed: post update
			if is_changed then
				if is_available then
					state = 'AVAILABLE'
					verb = if is_plural then 'are' else 'is' end
				else
					state = 'UNAVAILABLE'
					verb = if is_plural then 'appear to be' else 'appears to be' end
				end

				twitter_client.update("#{service_def['name']} #{verb} #{state}.")
			end
		rescue Exception => ex
			puts "Exception encountered while querying #{service_def['name']}: #{ex.message}"
			puts ex.backtrace.inspect
		end
	end


	# Create a client for interacting with a twitter account
	def self.get_twitter_client
		# Load config file
		opts = JSON.parse(File.read(TWITTER_CONFIG))
		# create client
		client = Twitter::REST::Client.new {|config|
			config.consumer_key = opts['consumer_key']
			config.consumer_secret = opts['consumer_secret']
			config.access_token = opts['access_token']
			config.access_token_secret = opts['access_token_secret']
		}
	end
end


# Run if this is file that was invoked
if __FILE__ == $0
	ServiceQuery.run
end
