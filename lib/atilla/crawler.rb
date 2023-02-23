require "byebug"
require "nokogiri"
require "typhoeus"
require "active_support/all"

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
		
	###############################################3
	## These options help to define the crawl process
	## :max_concurrency : how many urls can we hit at the same time. For eg: 10 would mean that we can issue 10 parallel request to the host. Defaults to 10
	## :url_pattern : if a specific pattern is to be crawled. For eg maybe you only want to crawl /articles. Just specify the pattern as a plain string. Defaults to "*"
	## :urls_file: if you want to crawl urls specified in a file -> sepcify the whole file path
	## :test_warm_cache -> if the first hit on a url reported a "MISS/EXPIRED" on the cache, will hit it again, to check whether the cache warmed up.
	###############################################
	def default_opts
		{
			"max_concurrency" => 10,
			"url_pattern" => "*",
			"urls_file" => nil,
			"test_warm_cache" => true
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
	end

	def parse_page(response)
		new_urls_added = 0
		doc = Nokogiri::HTML(response.body)
		canon = doc.xpath('//link[@rel="canonical"]/@href')

		# if a canonical exists and we have already completed it, then dont parse this, this makes sure that when the canonical itself comes in with a self ref -> it will parse.
		if canon and has_completed_url?(canon)
			
		else
			links = doc.css('a').map{|link|
				if link["href"] =~ /^#{Regexp.escape(self.host)}/
					if add_url(link["href"])
						new_urls_added += 1
					end
				elsif link["href"] =~ /^\//
					if add_url(self.host + link["href"])
						new_urls_added += 1
					end
				end
			}
		end
		new_urls_added
	end

	def has_completed_url?(url)
		!self.completed_urls[url].nil?
	end

	def has_url?(url)
		!(self.completed_urls[url].nil? and self.urls[url].nil?)
	end

	def add_url(url)
		# remove extra slashes
		k = url.gsub(/\/{2,}/,"/").gsub(/\/+$/,'').gsub(/http?\:\/w/,'https://').gsub(/https\:\/w/,'https://')
		# remove trailing slash
		if !has_url?(k)
			self.urls[k] = {}
			return true
		end
		return false
	end

	def run
		# just 
		self.seed_urls.uniq.each do |k|
			add_url(k)
		end
		while !self.urls.blank?
			new_urls_added = 0
			urls_removed = 0
			# init hydra
			crawled_in_this_run = []
			hydra = Typhoeus::Hydra.new(max_concurrency: self.opts["max_concurrency"])
			requests = self.urls.map{|url,value|
				crawled_in_this_run << url
				request = Typhoeus::Request.new(url, followlocation: true)
				hydra.queue(request)
				request
			}
			hydra.run
			responses = requests.map{|request|
				response = request.response
				if response.code.to_s == "500"
					# evict the url
				elsif response.code.to_s == "404"
					# transfer to the other map. 
				elsif response.code.to_s == "304"
					# since we already hit the cache, we can transfer.
				elsif response.code.to_s == "200" or response.code.to_s == "201" or response.code.to_s == "204"
					# if its the second run, 
					new_urls_added += parse_page(request.response)
				end
				#puts "deleting url #{request.url}"
			}

			crawled_in_this_run.each do |k|
				self.completed_urls[k] = self.urls.delete(k)
				urls_removed += 1
			end
			# discovered n new urls. 
			# removed y old urls.
			#puts JSON.pretty_generate(self.urls)
			#puts "urls become at the end"
			puts JSON.pretty_generate(self.urls)
			puts "discovered #{new_urls_added} new urls and crawled #{urls_removed}, total pending urls #{self.urls.size}"
			byebug
		end
	end

end	