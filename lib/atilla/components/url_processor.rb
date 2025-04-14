module Atilla::Components::UrlProcessor

	def url_file_type_regexes
		{
			"images" => "(jpg|jpeg|png|gif|bmp|webp|tiff|tif|svg)",
			"movies" => "(mp4|avi)",
			"files" => "(pdf|txt)",
			"others" => "(xml|tar|gz|zip)"
		}
	end


	def remove_query_params(url)
		clean_url = url.split(/[?#]/).first
		clean_url
	end

	def has_ignore_extensions?(url,opts)
		clean_url = remove_query_params(url).strip
		#puts "clean url #{clean_url}"
		regexes = opts["ignore_extensions"].map{|r| url_file_type_regexes[r]}.flatten.join("|")
		regex = /\.#{regexes}$/
		clean_url.match?(/#{regex}/)
	end

	# should end with html or have not ending .
	#[]
	# so in the crawls -> allow them.
	def allow_url_patterns?(url)
		clean_url = remove_query_params(url)

		patterns = self.opts['url_patterns'].map{|r| 
			unless r == ".*"
				Regexp.escape(r)
			else
				r
			end
		}.join('|')
		#write_log("permitted url patterns are #{patterns}","debug")
		if clean_url =~ /#{patterns}/i
			return true
		else
			return true if clean_url == self.host
			return false
		end
	end

	# just adds theh host url, scheme and port to the given url, normalizes it and returns it.
	def process_url(raw_url, opts={})

		
		is_host = (raw_url == self.host) || (self.host.blank?)

		
		#prepend http if there is no scheme, as addressable does no
		#not parse the host otherwise
		unless raw_url =~ /^(http|tel|mail)\:\/\//
			raw_url = "http://#{raw_url}"
		end

		
		uri = Addressable::URI.parse(raw_url)	  	

	  	if is_host
	  		opts[:host_scheme] = uri.scheme
	  		opts[:host_name] = uri.host
	  		opts[:host_port] = uri.port
	  		#puts "is host and opts become"
	  		# Normalize with your own normalization method
		  	output = {
		  		:url => NormalizeUrl.process(uri.to_s),
		  		:host_name => uri.host,
		  		:port => uri.port,
		  		:scheme => uri.scheme
		  	}
	  	else
	  		# there may be errors adding the host to 
	  		# some urls
	  		# these are usually malformed urls.
	  		# so in that case, we just return the raw_url as the
	  		# url for now.
	  		begin
	  			if uri.host.blank?
    				uri.host = opts[:host_name].to_s
    				if uri.port.blank?
	    				uri.port = opts[:host_port] if opts[:host_port]
	    			end
    			end
    			

			  	output = {
			  		:url => NormalizeUrl.process(uri.to_s),
			  		:host_name => uri.host,
			  		:port => uri.port,
			  		:scheme => uri.scheme
			  	}
	  		rescue => e
	  			puts e.to_s
	  			output = {
			  		:url => raw_url,
			  		:scheme => uri.scheme
			  	}
	  		end
	  	end

	  	output

	end

end