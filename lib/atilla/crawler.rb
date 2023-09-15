require "byebug"
require "nokogiri"
require "typhoeus"
require "active_support/all"
require "rack"
require "limiter"
require "addressable"
require "normalize_url"
require "fileutils"
require "ruby-progressbar"
require "concurrent-ruby"
require "sitemap-parser"
require "metainspector"
require "uri"
#require "robotstxt"

# so we can run it against a code. 
# like -> do we have a 500
# so we keep a finite length for urls.
# and change the slugs for the price urls too.
# take each one
# if display name is there change the slug
# if the short slug 
# if we change hte slug -> we have to look into price, package, symptom
# in all places it may have been changed.
# the ones which consist of a 
# remove all the long symptoms
# rebuild the slugs first. 
# then we can recrawl and check.
class Atilla::Crawler

	# the host : https://www.google.com | http://localhost:3000
	attr_accessor :host
	# you can start your crawl from multiple places in the target website. Make sure that these are full urls, including the host.
	attr_accessor :seed_urls
	attr_accessor :opts
	# the urls that are still to be crawled
	attr_accessor :urls
	# urls who were crawled are moved here.
	attr_accessor :completed_urls
	# trigger to halt the crawl, based on how many urls were cralwed
	attr_accessor :halt

	attr_accessor :crawl_started_at

	attr_accessor :urls_from_file

	attr_accessor :sitemap_urls

	attr_accessor :robots_parser

	attr_accessor :sitemap_discovered

	attr_accessor :sitemap_urls_count
		
	###############################################3
	## These options help to define the crawl process
	## :max_concurrency : how many urls can we hit at the same time. For eg: 10 would mean that we can issue 10 parallel request to the host. Defaults to 10
	## :url_patterns : if a specific pattern is to be crawled. For eg maybe you only want to crawl /articles. Just specify the pattern as a plain string. Defaults to "*"
	## :urls_file: if you want to crawl urls specified in a file -> sepcify the whole file path
	## :output_path : the full path of the file to write the crawl stats
	## :urls_limit : stop after crawling these many urls. eg : 10, defaults to nil, which means it will never break.
	## now in order to deploy this. 
	## for the free-data-viz.
	## end to end for 20 datasets.
	## then we look at the webui.
	## for this -> 
	###############################################
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

	def log_hierarchy
		["debug","info","error","fatal"]
	end

	def write_log(message,log_level="debug")
		allowed_index = log_hierarchy.index(self.opts["log_level"])
		#puts "allowed index #{allowed_index}"
		allowed = log_hierarchy[allowed_index..-1]
		#puts "allowed #{allowed}"
		#puts "incoming level #{log_level}"
		if allowed.include? log_level
			if self.opts["log_proc"]
				self.opts["log_proc"].call(message)
			end
			puts message
		else
			#puts "log not allowed"
		end
	end

	# For urls provided via files list, we ensure that the domain is local.
	def set_url_domain_to_host(url)
		uri = Addressable::URI.parse(url)
		host_uri = Addressable::URI.parse(self.host)
		l = uri.scheme + "://#{uri.host}"
		l2 = host_uri.scheme + "://#{host_uri.host}"
		url = url.gsub(/#{Regexp.escape(l)}/,l2)
		url
	end
	
	def crawl_sitemap
		set_robots_parser(self.host)

		if self.sitemap_urls.blank?
			self.sitemap_urls = [self.host + "/sitemap.xml"]
		end

		self.sitemap_urls.each do |sitemap_url|
			begin
				puts "checking sitemap url #{sitemap_url}"
				response = Typhoeus.get(sitemap_url)
				
				if response.code.to_s == "200"
					self.sitemap_discovered = true
				end

				sitemap = SitemapParser.new(sitemap_url,{recurse: true})
				write_log("hitting sitemap recursively","info")
				write_log(sitemap.to_a.to_s,"info")
				self.sitemap_urls_count = sitemap.to_a.size
				self.seed_urls << sitemap.to_a
				self.seed_urls.flatten!
				write_log("got #{self.seed_urls.size} urls","info")
			rescue => e
				write_log("failed to parse sitemap with error #{e.to_s}","error")
			end
		end
		
		#puts "got #{self.urls.size} urls from the sitemap"
		self.seed_urls.uniq!
		self.seed_urls.flatten!
		
	end

	def set_robots_parser(host)
		response = Typhoeus.get(host + "/robots.txt",{followlocation: true})
		if response.code.to_s == "200"
			write_log("got robots.txt","info")
			self.robots_parser = Robotstxt::Parser.new(self.opts["headers"]["User-Agent"],response.body)
			unless self.robots_parser.sitemaps.blank?
				write_log("robots.txt specified sitemaps","info")
				self.sitemap_urls = self.robots_parser.sitemaps
			else
				write_log("robots.txt does not specify a sitemap.","info")
			end
		end
	end

	def robots_allowed?(url)
		return true if self.robots_parser.blank?
		return self.robots_parser.allowed?(url)
	end

	## @param[String] base_url : the base_url of the website to be crawled. eg: http://www.google.com OR http://localhost:3000
	## @param[String] urls_file_absolute_path : If you want to limit the types of urls crawled using a file set the full and absolute path of the file here. 
	def initialize(host,seed_urls=[],opts={})
		self.host = host

		self.seed_urls = []

		self.opts = default_opts.deep_merge(opts)

		self.sitemap_urls = opts.delete("sitemap_urls")

		self.urls_from_file = []

		
		if self.opts["only_sitemap"]
			self.opts["crawl_discovered_urls"] = false
		elsif self.opts["urls_file"]
			
			self.opts["crawl_discovered_urls"] = false
			
			self.opts["normalize_urls"] = false

			file_urls = IO.read(self.opts["urls_file"]).split(/\n/)
			self.opts["urls_file_limit"] ||= file_urls.size

			file_urls[0..self.opts["urls_file_limit"]].each do |k|
				self.seed_urls << set_url_domain_to_host(k)
			end
		else
			if seed_urls.blank?
				self.seed_urls = [host]
			else
				self.seed_urls = seed_urls
			end
		end

		self.urls = {}
		self.completed_urls = {}
		self.halt = false
		self.crawl_started_at = Time.now


		create_crawl_output_dir
	end

	def output_file_path_prefix
		self.host.gsub(/\//,'-') + "-#{self.crawl_started_at.strftime("%Y-%m-%dT%H:%M:%S.%L%:z")}"
	end

	def get_crawl_output_dir_path
		self.opts["output_path"] + "/#{output_file_path_prefix}"
	end

	def create_crawl_output_dir
		return unless self.opts["save_output"] == true
		if self.opts["output_path"].blank?
			raise "please specify an output path for the directory that will hold the crawl results"
		end
		FileUtils.mkdir_p(self.opts["output_path"] + "/#{output_file_path_prefix}")
	end
	
	def extract_shortlink_href(doc)
	  # To extract the href attribute value using CSS selector
	  shortlink_node = doc.at('link[rel="shortlink"][type="text/html"]')
	  return shortlink_node['href'] if shortlink_node
	  return nil
	end

	def parse_page(response,url)
		new_urls_added = 0
		doc = Nokogiri::HTML(response.body)
		canon = doc.xpath('//link[@rel="canonical"]/@href')
		# ADD CANONICAL URL.
		self.urls[url]["CANONICAL_URL"] = canon.text if (canon and (!canon.text.strip.blank?))

		self.urls[url]["SHORT_URL"] = extract_shortlink_href(doc)

		return new_urls_added unless self.opts["crawl_discovered_urls"]
		if response.code.to_s == "301" or response.code.to_s == "302" or response.code == "308"
			if add_url(response.headers["LOCATION"],{"referrer" => url, "redirected_from" => url})
				new_urls_added += 1
			end
			return new_urls_added
		else
			# if a canonical exists and we have already completed it, then dont parse this, this makes sure that when the canonical itself comes in with a self ref -> it will parse.
			if canon and !canon.text.strip.blank? and has_completed_url?(canon.text)
				#puts "this is canonical"
			else
				## PROCESS OUTLINKS.
				doc.css('a').each do |link|
					

					next if link["rel"] =~ /nofollow/
					next if link["href"] == "#"
					next if link["href"].blank?
					next if link["href"].strip.blank?

					if link["href"] =~ /^#{Regexp.escape(self.host)}/
						if add_url(link["href"],{"referrer" => url})
							new_urls_added += 1
						end
					elsif link["href"] =~ /^(https?\:|www\.)/
						#puts "its another domain"
					else
						href = link["href"]
						#puts "href is #{href}, host is#{self.host}, #{link.text}"
						if add_url(self.host + href,{"referrer" => url})
							new_urls_added += 1
						end
					end
				end
			end
			return new_urls_added
		end
	end

	def has_completed_url?(url)
		!self.completed_urls[url].nil?
	end

	def has_url?(url)
		!(self.completed_urls[url].nil? and self.urls[url].nil?)
	end

	########## DISASSEMBLE AND REASSEMBLE THE QUERY STRING
	# If the url already has some parameters -> we first decipher that into a hash. 
	# then merge in any parameters passed into the crawler
	# rebuild the query string
	# append to the url.
	# if we follow a redirect, will it pass forward the query params. 
	# and in this case what will it do -> 
	#########
	def append_params(url)
		existing_params = {}
		# this followed by equal to .
		# dog?cat=10
		# exp
		if query_string = url.match(/\?[^\=]+\=.+$/)
			existing_params = Rack::Utils.parse_nested_query(query_string[0])
		end
		unless self.opts["params"].blank?
			existing_params.merge!(self.opts["params"])
		end
		
		## Remove existing query params.
		url = url.gsub(/\?[^\=]+\=.+$/,'')

		
		## APPEND REBUILT QUERY PARAMS.
		param_string = existing_params.to_param
		param_string.gsub!(/^\%3F/,'')
		param_string.gsub!(/^\?/,'')

		unless param_string.blank?
			url = url + "?" + param_string
		end

		## FOR SOME REASON THIS URL ENCODES, SO DECODE THE ? PARAM.
		url
	end

	# so in the crawls -> allow them.
	def allow_url_patterns?(url)
		if url =~ /#{self.opts['url_patterns'].map{|r| 
			unless r == ".*"
				Regexp.escape(r)
			else
				r
			end
		}.join('|')}/i
			return true
		else
			return true if url == self.host
			return false
		end
	end

	def belongs_to_host?(url)
		uri = URI(url)
		uri.host == URI(self.host).host
	end

	def add_url(url,opts={})
		begin
			url = NormalizeUrl.process(url) if self.opts["normalize_urls"]
			
			write_log("url after normalization #{url}","debug")

			unless belongs_to_host?(url)
				write_log("url #{url} does not belong to host","debug")
				return false 
			end

			unless robots_allowed?(url)
				write_log("url #{url} not allowed by robots.txt","debug")
				return false 
			end

			unless allow_url_patterns?(url)
				write_log("url #{url} not allowed via specified patterns #{self.opts['url_patterns']}","debug")
				return false
			end

			
			k = append_params(url)
			# remove trailing slash

			#return false if url =~ /\.pdf/

			if !has_url?(k)
				# if the 
				unless self.opts["urls_limit"].blank?
					if (self.urls.size + self.completed_urls.size) > self.opts["urls_limit"]
						#puts "hit size limit #{self.urls.size}"
						return false
					end
				end

				self.urls[k] = {"REFERRING_URLS" => []}
				unless opts["referrer"].blank?
					self.urls[k]["REFERRING_URLS"] << opts["referrer"]
				end

				write_log("added url #{k}","debug")
				#puts "added url #{k}"
				return true
			else
				# add the referred if the url already exists and the referrer does not.
				#puts "url already exists #{k}"
				if self.urls[k]
					unless self.urls[k]["REFERRING_URLS"].include? opts["referrer"]
						self.urls[k]["REFERRING_URLS"] << opts["referrer"]
						self.urls[k]["TOTAL_REFERRING_URLS"] = self.urls[k]["REFERRING_URLS"].size
					end
				end

				if self.completed_urls[k]
					unless self.completed_urls[k]["REFERRING_URLS"].include? opts["referrer"]
						self.completed_urls[k]["REFERRING_URLS"] << opts["referrer"]
						self.completed_urls[k]["TOTAL_REFERRING_URLS"] = self.completed_urls[k]["REFERRING_URLS"].size
					end
				end
			end
			return false
		rescue => e
			write_log("url #{url} could not be added due to error #{e.message} #{e.backtrace.to_s}","error")
			return false
		end
	end

	def parse_page_codes
		["204","201","200","301","302"]
	end

	def meta_inspect(url,response)
		page = MetaInspector.new(url, :document => response.body)
		{
			"title" => page.best_title,
			"description" => page.best_description,
			"images" => page.images.map{|r| r.to_s}
		}
	end

	def update_page_info(request,response,new_urls_added,url)

		
		self.urls[url].merge!(response.headers)
		# MERGE URL COUNT
		self.urls[url].merge!({"URL_LENGTH" => url.length})

		self.urls[url]["URL_PARTS"] = []
		uri = Addressable::URI.parse(url)
		uri.path.split(/\//).size.times do |m|
			if m > 0
				self.urls[url]["URL_PARTS"] << uri.path.split(/\//)[0..m].join("/") 
			end
		end
		
		self.urls[url]["TIME_TO_FIRST_BYTE"] = response.starttransfer_time

		self.urls[url]["TOTAL_TIME"] = response.total_time

		self.urls[url]["TRANSFER_TIME"] = response.total_time - response.starttransfer_time

		## NERGE RESPONSE CODE.
		self.urls[url].merge!({
			"RESPONSE_CODE" => response.code
		})

		self.urls[url]["HOST"] = self.host

		self.urls[url]["URL"] = url

		self.urls[url].merge!(meta_inspect(url,response))
		
		if parse_page_codes.include? response.code.to_s
			#puts "parsing page -- "
			res = parse_page(response,url)
			
			new_urls_added += res
		end



	end

	

	def write_failed_urls(h)
		pth = get_crawl_output_dir_path + "/could_not_crawl.json"
		IO.write(pth,JSON.pretty_generate(h))
	end

	def write_completed_urls
		pth = get_crawl_output_dir_path + "/all_crawled.json"
		IO.write(pth,JSON.pretty_generate(self.completed_urls))
		write_code_wise_urls(self.completed_urls)
	end

	## FOR EACH ERROR CODE IT WILL OUTPUT A FILE with each url delimited by a new line.
	def write_code_wise_urls(urls_hash)
		
		response_codes = {}

		urls_hash.keys.each do |url|
			response_codes[urls_hash[url]["RESPONSE_CODE"].to_i] ||= []
			response_codes[urls_hash[url]["RESPONSE_CODE"].to_i] << url
		end

		response_codes.each do |code,urls|
			pth = get_crawl_output_dir_path + "/#{code.to_s}.json"
			IO.write(pth,urls.join("\n"))
		end
	end

	# returns the entire crawled list of urls.
	def get_all_crawled_urls
		JSON.parse(IO.read(self.get_crawl_output_dir_path + "/all_crawled.json"))
	end

=begin
	# writes a kibana friendly json file. 
	# uses the index name from the opts. 
	# defaults to "crawl_responses"
	def write_kibana_friendly_json	
		kfriendly = self.completed_urls.map{|r,v|
			v.merge({"URL" => r})
		}.flatten
		IO.write((self.opts["output_path"] + "/kibana_friendly_crawl.json"),kfriendly.map{|r| JSON.generate(r)}.join("\n"))
	end
=end

=begin
			requests = self.urls.map{|url,value|
				#puts "doing url #{url}"
				crawled_in_this_run << url
				request = Typhoeus::Request.new(url, headers: self.opts["headers"], connecttimeout: 1, timeout: 3)

				request.on_complete do |response|
					#k.delete(request.url)
			      	rate_queue.shift
			    end
				hydra.queue(request)
				request
			}
			

			write_log("#{requests.size} requests queued")
			
			hydra.run

			responses = requests.each_with_index{|request,key|
				response = request.response
				update_page_info(request,response,new_urls_added,request.base_url)
			}

			write_log("completed -- ")
=end
	def crawl_sitemap

	end
	# this must be lower.
	# otherwise doesnt make sense.
	def run

		write_log("started crawl","info")

		if self.opts["discovery"] == true
			write_log("not crawling urls as we are in discovery mode","info")
			return 

		end

		rate_queue = ::Limiter::RateQueue.new(self.opts["requests_per_second"], interval: 1)

		## ADD URLS FROM THE URL FILE.
		##byebug
		write_log("seed urls size #{self.seed_urls.size}","info")

		self.seed_urls.uniq.each do |k|
			add_url(k)
		end
		
		failed_to_correlate_urls = {}
		new_urls_added = 0
		urls_removed = 0

		crawled_in_this_run = []

		max_con = self.opts["max_concurrency"] > self.opts["requests_per_second"] ? self.opts["requests_per_second"] : self.opts["max_concurrency"]

		hydra = Typhoeus::Hydra.new(max_concurrency: max_con)

		write_log("started crawl with total urls #{self.urls.size}","info")

		while !self.urls.blank?

			urls_snap = Marshal.load(Marshal.dump(self.urls.keys))

			write_log("starting crawl of #{urls_snap.size} urls, at the rate of #{self.opts['max_concurrency']}/requests per second, in batches of #{self.opts['urls_per_batch']} urls.","info")


			progressbar = ProgressBar.create(:total => urls_snap.size, format: "%a %e %P% Processed: %c from %C")

			urls_snap.each_slice(self.opts["urls_per_batch"]) do |url_batch|
				
				requests = url_batch.map{|url|
					request = Typhoeus::Request.new(url, headers: self.opts["headers"], connecttimeout: 1, timeout: 3)

					request.on_complete do |response|
						#k.delete(request.url)
				      	rate_queue.shift
				    end
					hydra.queue(request)
					request
				}

				#write_log("#{requests.size} requests queued")
			
				hydra.run

				responses = requests.each_with_index{|request,key|
					response = request.response
					update_page_info(request,response,new_urls_added,request.base_url)
					progressbar.increment
				}

				url_batch.map{|url,value|
					self.completed_urls[url] = self.urls.delete(url)
					urls_removed += 1
				}

				# so how to constrain.
				# reschedule a post only for a particular network.
				# what about summarize this
				# how many did you complete.
				#write_log("Completed batch of #{url_batch.size}, Total Crawled on Domain #{self.completed_urls.size} -- discovered #{new_urls_added} new urls, total pending urls #{self.urls.size} ")
			end

		end

		
		#write_log("discovered #{new_urls_added} new urls and crawled #{urls_removed}, total pending urls #{self.urls.size}, total crawled urls #{self.completed_urls.size}")


		#end

		if self.opts["save_output"]
			write_completed_urls
			
			write_failed_urls(failed_to_correlate_urls)
		end
	end

	
end	