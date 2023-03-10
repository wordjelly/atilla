require "csv"
# Parses outputs of google search console crawls
# converts the csv files to simple text files where each line constains a single comma seperated url.
# you can specify a host parameter to change the host of each url.
# this is helpful if you are testing a production domain against a development server.
# for eg : your production domain is www.production.com
# and you are testing with localhost.
# so all the urls in google_console csv output will be rewritten using the host="http://localhost:3000".
class Atilla::GoogleSearchConsoleParser

	attr_accessor :csv_file_path
	attr_accessor :csv_dir_path
	attr_accessor :host
	# the reason for which google flagged these urls.
	attr_accessor :error_reason

	# we should make this a module
	# so that we can 
	def initialize(csv_file_path=nil)
		self.csv_file_path = csv_file_path
	end

	# Atilla::GoogleSearchConsoleParser.parse_directory()
	def self.parse_directory(dir_path)
		all_urls = []
		host = nil
		Dir.glob(dir_path + "/*.csv").each do |csv_file|
			csv = Atilla::GoogleSearchConsoleParser.new(csv_file)
			res = csv.parse_csv
			all_urls << res["urls"]
			host = res.delete("host")
		end
		all_urls.flatten!
		write_urls(all_urls,host)
	end

	def self.write_urls(urls,host)
		#error_reason = self.error_reason || "unknown_error"
		#puts "host #{host}, error reason #{error_reason}"
		filename = host + "#{Time.now.strftime("%Y-%m-%d")}"

		pth = (__FILE__.split(/\//)[0..-4].join("/") + "/output/url_lists/#{filename}.txt")
		IO.write(pth,urls.join("\n"))
		return pth
	end
	
	def parse_csv
		urls = []
		puts "csv file path #{self.csv_file_path}"
		data = ::CSV.parse(IO.read(self.csv_file_path), headers: %i[URL Last crawled])
		data.each_with_index{|row,key|
			next if key == 0
			urls << row.to_h[:URL].gsub(/\n/,'')
		}

		uri = Addressable::URI.parse(urls[0])
		host = uri.host
		{"host" => host, "urls" => urls}
	end

end