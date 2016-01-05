require 'twitter'
require './services.rb'


module ServiceQuery
	# Path to service definition file
	SERVICE_CONFIG = './conf/services.json'

	# Path to twitter configuration file
	TWITTER_CONFIG = './conf/twitter.json'


	# Query services and post any updates to twitter
	def run
		# Load configuration
		twitter_client = get_twitter_client
		service_defs = get_service_defs

		# Query services
		query_services(twitter_client, service_defs)

		# Save configuration
		write_service_defs(service_defs)
	end


	# Load service definitions
	def load_service_defs
		TribesNext.read_config(SERVICE_CONFIG)
	end


	# Save service definitions
	def write_service_defs(service_defs)
		TribesNext.write_config(SERVICE_CONFIG, services)
	end


	# Query services, and post updates if any have changed availability
	def query_services(twitter_client, service_defs)
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
	def query_service(twitter_client, service_def)
		begin
			plural? = ('s' === service_def['name'])
			available?, changed? = TribesNext.query(service_def)

			# if state changed: post update
			if changed? then
				if available? then
					state = 'AVAILABLE'
					verb = if plural? then 'are' else 'is' end
				else
					state = 'UNAVAILABLE'
					verb = if plural? then 'appear to be' else 'appears to be' end
				end

				twitter_client.update("#{service_def['name']} #{verb} #{state}.")
			end
		rescue Exception => ex
			puts "Exception encountered while querying #{service['name']}: #{e.message}"
			puts e.backtrace.inspect if debug?
		end
	end


	# Create a client for interacting with a twitter account
	def get_twitter_client
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
