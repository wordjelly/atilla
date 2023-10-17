module Atilla::Components::Robots
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
end