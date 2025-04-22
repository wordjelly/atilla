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

	def valid_top_level_domain?(url)
		url =~ /\b(#{self.opts["valid_top_level_domains"].map{|opt| Regexp.escape(opt)}.join("|")})\b/
	end

	def host_blank?(uri)
		resp = uri.host.blank?
		write_log("host blank #{resp.to_s} #{uri.to_s}","debug")
		resp
	end

	def different_host_and_invalid_tld?(uri)
		different_host = (uri.host != self.opts[:host_name])
		invalid_tld = (!valid_top_level_domain?(uri.to_s))
		write_log("different host #{different_host.to_s} and invalid tld #{invalid_tld.to_s}, self host is #{self.opts[:host_name]}, uri host is #{uri.host}","debug")
		different_host and invalid_tld
	end

	# when we want to prepend our host and scheme to a uri, we need to remove its detected scheme first.
	# since this is only done in cases where url is detected as not being either a valid outside url or an internal url.
	def raw_url_without_scheme(raw_url,uri)
		existing_scheme = uri.scheme || ''
		unless existing_scheme.blank?
			existing_scheme += "://"
		end
		uri.to_s.gsub(/#{Regexp.escape(existing_scheme)}/,'')
	end

	# just adds theh host url, scheme and port to the given url, normalizes it and returns it.
	def process_url(raw_url, opts={})
		write_log("processing #{raw_url}","debug")
		begin
			is_host = (raw_url == self.host) || (self.host.blank?)

			write_log("#{raw_url} is_host #{is_host}","debug")
			#prepend http if there is no scheme, as addressable does no
			#not parse the host otherwise
			#appended_url = nil
			append_http = false
			unless raw_url =~ /^(https?|tel|mail)\:\/\//
				append_http = true
			end

			#puts "appended url #{appended_url}"
			uri = nil
			if append_http
				uri = Addressable::URI.parse("http://#{raw_url}")
			else
				uri = Addressable::URI.parse(raw_url)
			end
			
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
		  		begin
		  			# set host only if the uri host is blank, or it is not our host, and has an invalid domain ending.
		  			if (host_blank?(uri) or different_host_and_invalid_tld?(uri))
		  			
		  				existing_scheme = uri.scheme || ''
		  				unless existing_scheme.blank?
		  					existing_scheme += "://"
		  				end

		  				uri = Addressable::URI.parse(opts[:host_scheme] + "://" + opts[:host_name] + "/" + raw_url_without_scheme(raw_url,uri))
		  				
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
		  			write_log({:message => "Error in normalizing url #{appeneded_url} with message #{e.message}"},"error",e)
		  			#puts e.to_s
		  			output = {
				  		:url => appeneded_url,
				  		:scheme => uri.scheme
				  	}
		  		end
		  	end

		  	output
	  	rescue => e
	  		#puts e.to_s
	  		#puts e.backtrace.join('\n')
	  		write_log({:message => "Error processing url #{raw_url} with message #{e.message}"},"error",e)
	  		{
	  			:url => raw_url
	  		}
	  	end

	end

end