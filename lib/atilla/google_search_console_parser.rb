# Parses outputs of google search console crawls
# converts the csv files to simple text files where each line constains a single comma seperated url.
# you can specify a host parameter to change the host of each url.
# this is helpful if you are testing a production domain against a development server.
# for eg : your production domain is www.production.com
# and you are testing with localhost.
# so all the urls in google_console csv output will be rewritten using the host="http://localhost:3000".
class Atilla::GoogleSearchConsoleParser

	attr_accessor :csv_file_path
	attr_accessor :host
	# the reason for which google flagged these urls.
	attr_accessor :error_reason

	def initialize(csv_file_path,host=nil,error_reason=nil)
		self.csv_file_path = csv_file_path
		self.host = host
	end
	
	def parse_csv
		urls = []
		IO.read(self.csv_file_path).each_line do |l|
			urls << l.split(",")[0]
		end
		inherent_host = nil
		unless self.host.blank?
			urls.map!{|u|
				uri = Addressable::URI.parse(response.effective_url)
				inherent_host = uri.host
				self.host.gsub(/\/+$/,'/') + uri.path
			}
		end
		filename = (self.host || inherent_host) + "_#{self.error_reason}_#{Time.now.strftime("yyyy MM DD")}"
		pth = (__FILE__.split(/\//)[0..-3].join("/") + "/output/url_lists/#{filename}.txt")
		IO.write(pth,urls.join("\n"))
	end

end