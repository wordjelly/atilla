require "byebug"
require "nokogiri"
require "typhoeus"
require "active_support/all"
require "rack"
require "limiter"
require "addressable"

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

		
	###############################################3
	## These options help to define the crawl process
	## :max_concurrency : how many urls can we hit at the same time. For eg: 10 would mean that we can issue 10 parallel request to the host. Defaults to 10
	## :url_pattern : if a specific pattern is to be crawled. For eg maybe you only want to crawl /articles. Just specify the pattern as a plain string. Defaults to "*"
	## :urls_file: if you want to crawl urls specified in a file -> sepcify the whole file path
	## :output_path : the full path of the file to write the crawl stats
	## :urls_limit : stop after crawling these many urls. eg : 10, defaults to nil, which means it will never break.
	###############################################
	def default_opts
		{
			"params" => {},
			"max_concurrency" => 200,
			"requests_per_second" => 30,
			"url_pattern" => "*",
			"urls_file" => nil,
			# path at which to write the output
			"output_path" => nil,
			"urls_limit" => nil,
			"kibana_index_name" => "crawl_responses"
		}
	end

	## @param[String] base_url : the base_url of the website to be crawled. eg: http://www.google.com OR http://localhost:3000
	## @param[String] urls_file_absolute_path : If you want to limit the types of urls crawled using a file set the full and absolute path of the file here. 
	def initialize(host,seed_urls=[],opts={})
		self.host = host
		if seed_urls.blank?
			self.seed_urls = [host]
		else
			self.seed_urls = seed_urls
		end
		self.opts = default_opts.merge(opts)
		self.urls = {}
		self.completed_urls = {}
		self.halt = false

	end
	
	# this should be called parse page url.
	def parse_page(response,url)
		new_urls_added = 0
		doc = Nokogiri::HTML(response.body)
		canon = doc.xpath('//link[@rel="canonical"]/@href')
		# ADD CANONICAL URL.
		self.urls[url]["CANONICAL_URL"] = canon if (canon and (!canon.text.strip.blank?))
		# if a canonical exists and we have already completed it, then dont parse this, this makes sure that when the canonical itself comes in with a self ref -> it will parse.
		if canon and !canon.text.strip.blank? and has_completed_url?(canon.text)

		else
			## PROCESS OUTLINKS.
			doc.css('a').each do |link|
				next if link["rel"] =~ /nofollow/
				if link["href"] =~ /^#{Regexp.escape(self.host)}/
					if add_url(link["href"],{"referrer" => url})
						new_urls_added += 1
					end
				elsif link["href"] =~ /^\//
					if add_url(self.host + link["href"],{"referrer" => url})
						new_urls_added += 1
					end
				end
			end
		end
		new_urls_added
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
		if query_string = url.match(/\?.+$/)
			existing_params = Rack::Utils.parse_nested_query(query_string[0])
		end
		unless self.opts["params"].blank?
			existing_params.merge!(self.opts["params"])
		end
		
		## Remove existing query params.
		url = url.gsub(/\?.+$/,'')

		## APPEND TRAILING SLASH IF MISSING.
		unless url =~ /\/$/
			url = url + "/"
		end

		## APPEND REBUILT QUERY PARAMS.
		param_string = existing_params.to_param
		param_string.gsub!(/^\%3F/,'')
		param_string.gsub!(/^\?/,'')

		url = url + "?" + param_string

		## FOR SOME REASON THIS URL ENCODES, SO DECODE THE ? PARAM.
		url
	end

	def add_url(url,opts={})
		# remove extra slashes
		k = url.gsub(/\/{3,}/,"//")
		k = append_params(k)
		# remove trailing slash
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
	end

	def parse_page_codes
		["204","201","200"]
	end

	# now given this file, we can simply index it into es. 
	# how do we get the 

	def update_page_info(request,response,new_urls_added)
		self.urls[response.effective_url].merge!(response.headers)
		# MERGE URL COUNT
		self.urls[response.effective_url].merge!({"URL_LENGTH" => response.effective_url.length})

		self.urls[response.effective_url]["URL_PARTS"] = []
		uri = Addressable::URI.parse(response.effective_url)
		uri.path.split(/\//).size.times do |m|
			if m > 0
				self.urls[response.effective_url]["URL_PARTS"] << uri.path.split(/\//)[0..m].join("/") 
			end
		end
		
		self.urls[response.effective_url]["TIME_TO_FIRST_BYTE"] = response.starttransfer_time

		self.urls[response.effective_url]["TOTAL_TIME"] = response.total_time

		self.urls[response.effective_url]["TRANSFER_TIME"] = response.total_time - response.starttransfer_time

		

		## NERGE RESPONSE CODE.
		self.urls[response.effective_url].merge!({
			"RESPONSE_CODE" => response.code
		})

		if parse_page_codes.include? response.code.to_s
			new_urls_added += parse_page(response,response.effective_url)
		end

	end

	def write_failed_urls(h)
		IO.write((self.opts["output_path"] + "/failures.json"),JSON.pretty_generate(h))
	end

	def write_completed_urls
		IO.write((self.opts["output_path"] + "/crawl.json"),JSON.pretty_generate(self.completed_urls))
	end

	# writes a kibana friendly json file. 
	# uses the index name from the opts. 
	# defaults to "crawl_responses"
	def write_kibana_friendly_json	
		kfriendly = self.completed_urls.map{|r,v|
			v.merge({"URL" => r})
		}.flatten
		IO.write((self.opts["output_path"] + "/kibana_friendly_crawl.json"),kfriendly.map{|r| JSON.generate(r)}.join("\n"))
	end

	def run
		if self.opts["output_path"].blank?
			puts "you have not specified an output path for the url stats file, do you want to continue? The results of the crawl should be persisted if you want to visualize them! [Yn]"
			a = gets.chomp
			if !(a =~ /y/i)
				puts "aborting run as there is no output path specified."
				return
			end
		end
			
		rate_queue = ::Limiter::RateQueue.new(self.opts["requests_per_second"], interval: 1)

		self.seed_urls.uniq.each do |k|
			add_url(k)
		end

		## ADD URLS FROM THE URL FILE.
		if self.opts["urls_file"]
			IO.read(self.opts["urls_file"]).split(/\n/).each do |k|
				add_url(k)
			end
		end

		failed_to_correlate_urls = {}

		while !self.urls.blank?
			new_urls_added = 0
			urls_removed = 0
			# init hydra

			crawled_in_this_run = []
			hydra = Typhoeus::Hydra.new(max_concurrency: self.opts["max_concurrency"])

			# lets say the homepage discovered 40 urls.
			# then we crawled them
			# and discovered
			requests = self.urls.map{|url,value|
				crawled_in_this_run << url
				request = Typhoeus::Request.new(url)
				request.on_complete do |response|
			      rate_queue.shift
			    end
				hydra.queue(request)
				request
			}
			hydra.run
			responses = requests.each_with_index{|request,key|
				response = request.response
				begin
					update_page_info(request,response,new_urls_added)
				rescue => e
					puts "error #{e}"
					puts response.effective_url
					puts "--- fail output ends -- "
					url = crawled_in_this_run[key].encode("UTF-8", invalid: :replace, undef: :replace)
					failed_to_correlate_urls[url] = response.effective_url.encode("UTF-8", invalid: :replace, undef: :replace)
				end
			}

			crawled_in_this_run.each do |k|
				self.completed_urls[k] = self.urls.delete(k)
				urls_removed += 1
			end
			
			puts "discovered #{new_urls_added} new urls and crawled #{urls_removed}, total pending urls #{self.urls.size}, total crawled urls #{self.completed_urls.size}"


		end

		write_completed_urls
		# lets rewire the slugs. 
		# to give the root path as canonical.
		# lets do this as step one.
		# knock off all the categories
		# i don't want it to crawl that. 
		# puts a noindex on them.
		# either we change all the canonical urls 
		# to the root path. 
		# and redirect everything else to that.
		# and also shorten the urls.
		# so any place where the slug length is longer than x.
		# http://192.168.1.2/diagnostics/reports/
		#write_kibana_friendly_json
		write_failed_urls(failed_to_correlate_urls)

	end

	

end	