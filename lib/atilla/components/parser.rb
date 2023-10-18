module Atilla::Components::Parser
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
					
					begin
						ur = URI.parse(URI.join(self.host,link['href']).to_s)
						if ur.host != URI.parse(self.host).host
							puts "link #{link['href']} host #{ur.host}, is different from self.host"
						else
							add_url(URI.join(self.host,link['href']).to_s)
							new_urls_added += 1
							#byebug
						end
					rescue => e
						puts e.message.to_s
						
						#puts "got error"
						#sbyebug
					end
				end
			end
			return new_urls_added
		end
	end
end