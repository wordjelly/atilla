module Atilla::Components::Sitemap
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

end