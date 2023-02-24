require 'elasticsearch/persistence'

class Atilla::Es

	def self.bulk_index(urls_hash,index_name)
		bulk_requests = []
		urls_hash.keys.each do |url|
			
			bulk_requests << {
				update: {
					_index: index_name,
					_type: "_doc",
					_id: (urls_hash[url]["X-Request-Id"] || SecureRandom.uuid),
					data: {
						doc_as_upsert: true,
						doc: urls_hash[url].merge({"URL" => url})
					}
				}	
			}
			if bulk_requests.size > 100
				puts Elasticsearch::Persistence.client.bulk body: bulk_requests
				bulk_requests = []
			end
		end
		if bulk_requests.size > 0
			puts Elasticsearch::Persistence.client.bulk body: bulk_requests
			bulk_requests = []
		end
	end

	def self.index_definition
		{
			mappings: {
				properties: {
				  "REFERRING_URLS"=> {
				    "type"=> "keyword"
				  },
				  "Server"=> {
				    "type"=> "keyword"
				  },
				  "Date"=> {
				    "type"=> "keyword"
				  },
				  "Content-Type"=> {
				    "type"=> "keyword"
				  },
				  "Transfer-Encoding"=> {
				    "type"=> "keyword"
				  },
				  "Connection"=> {
				    "type"=> "keyword"
				  },
				  "X-Frame-Options"=> {
				    "type"=> "keyword"
				  },
				  "X-XSS-Protection"=> {
				    "type"=> "keyword"
				  },
				  "X-Content-Type-Options"=> {
				    "type"=> "keyword"
				  },
				  "X-Download-Options"=> {
				    "type"=> "keyword"
				  },
				  "X-Permitted-Cross-Domain-Policies"=> {
				    "type"=> "keyword"
				  },
				  "Referrer-Policy"=> {
				    "type"=> "keyword"
				  },
				  "Cache-Control"=> {
				    "type"=> "keyword"
				  },
				  "ETag"=> {
				    "type"=> "keyword"
				  },
				  "Set-Cookie"=> {
				    "type"=> "keyword"
				  },
				  "X-Request-Id"=> {
				    "type"=> "keyword"
				  },
				  "X-Runtime"=> {
				    "type"=> "float"
				  },
				  "X-Cache-Status"=> {
				    "type"=> "keyword"
				  },
				  "URL_LENGTH"=> {
				    "type"=> "float"
				  },
				  "URL_PARTS"=> {
				    "type"=> "keyword"
				  },
				  "TIME_TO_FIRST_BYTE"=> {
				    "type"=> "float"
				  },
				  "TOTAL_TIME"=> {
				    "type"=> "float"
				  },
				  "TRANSFER_TIME"=> {
				    "type"=> "float"
				  },
				  "RESPONSE_CODE"=> {
				    "type"=> "float"
				  },
				  "TOTAL_REFERRING_URLS"=> {
				    "type"=> "float"
				  }
				}
			}
		}
	end

	def self.build_props
		properties = {}
		hit = JSON.parse(IO.read("/home/bhargav/Github/atilla/output/crawl.json")).values[0]
		hit.keys.each do |k|
			type = "keyword"
			begin
				Float(hit[k])
				type = "float"
			rescue

			end
			properties[k] = {type: type}
		end
		puts JSON.pretty_generate(properties)
	end

	def self.create_index(index_name)
		Elasticsearch::Persistence.client.indices.create index: index_name, :body => index_definition
	end

	def self.delete_index(index_name)
		begin
			Elasticsearch::Persistence.client.indices.delete index: index_name
		rescue Elasticsearch::Transport::Transport::Errors::NotFound
			puts "index not found"
		end
	end

end