module Atilla::Components::Crawler
	
	def poll
		# in a while loop, polls the list for any url that should be crawled
		# listens to a wipe queue signal
	end

	private
	def default_opts
		{ 
			## whether to save the output of the crawl , this is FALSE by default. 
			"urls_per_batch" => 10,
			"save_output" => false,
			"params" => {},
			"max_concurrency" => 5,
			"headers" => {
				"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36",
				"Content-Type" => "text/html",
				"Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
				#{}"Accept-Encoding" => "gzip, deflate"
			},
			"requests_per_second" => 1,
			"url_patterns" => [".*"],
			"urls_file" => nil,
			"urls_file_limit" => nil,
			# path at which to write the output
			"output_path" => nil,
			"urls_limit" => nil,
			"only_sitemap" => false,
 			"kibana_index_name" => "crawl_responses",
			# when we are on a given page, we may discover n urls. if set to true -> it will crawl those pages as well. Turned to default "false" in case "urls_file" is provided.
			"crawl_discovered_urls" => true,
			# whether to normalize incoming urls. turned to "false" by default in case "urls_file" is provided.
			"normalize_urls" => true,
			"log_level" => "debug",
			"discovery" => false
		}
	end

end