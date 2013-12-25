#!/usr/bin/env ruby

require 'json'
require 'rest_client'


# Get the list of labels for a list of IDs.
#
# * (string)  uri           - The URI of the sign in route. This URI involves the base dictionary name.
#                             (e.g., http://localhost:3000/dictionaries/EntrezGene%20-%20Homo%20Sapiens)
# * (string)  email         - User's login ID.
# * (string)  password      - User's login password.
# * (hash)    annotation    - The hash including a list of labels.
# * (hash)    options       - The hash containig options for id search.
#
def get_idlists(uri, email, password, annotation, options)
	# Prepare the connection to the web service.
	resource = RestClient::Resource.new( 
		"#{uri}/terms_to_idlists.json",
		:timeout      => 300, 
		:open_timeout => 300,
		)

	# Retrieve the list of labels.
	data = resource.post( 
		:user         => {email:email, password:password},
		:annotation   => annotation.to_json,
		:options      => options.to_json, 
		:content_type => :json,
		:accept       => :json,
	) do |response, request, result|
		case response.code
		when 200
			JSON.parse(response.body)
		else
			$stdout.puts "Error code: #{response.code}"
			annotation
		end
	end

	return data
end



# Text code.
#
# * ARGV[0]  -  User's email.
# * ARGV[1]  -  User's password.
# * ARGV[2]  -  URI
#
if __FILE__ == $0
	if ARGV.size != 3
		$stdout.puts "Usage:  #{$0}  Email  Password  URI"
		exit
	end
	email      = ARGV[0]
	password   = ARGV[1]
	uri        = ARGV[2]


	# Prepare data and option objects
	annotation = { "terms" => [ "NF-kappa B", "C-REL", "c-rel", "may_be_not_exist"] }
	options    = { "threshold" => 0.3, "top_n" => 10 }

	result     = get_idlists(uri, email, password, annotation, options)

	$stdout.puts "Input:"
	$stdout.puts annotation["terms"].inspect
	
	$stdout.puts "Output:"
	if result.has_key? "error"
		$stdout.puts "   Error: #{result["error"]["message"]}"
	end
	if result.has_key? "idlists"
		$stdout.puts "   %-20s| %s" % ["TERM", "IDs"]
		annotation["terms"].each do |term|
			$stdout.puts "   %-10s| %s" % [term, result["idlists"][term].inspect]
		end
	end
	$stdout.puts 

end