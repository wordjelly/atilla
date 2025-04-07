module Atilla::Components::Seo
	# checks all the crawled urls, and outputs a csv of the urls with titles, descriptions and keywords
	def titles_descriptions_keywords_csv(fpath,csv_output_path,response_codes=[-1])
		dump = JSON.parse(IO.read(fpath))
		arr = []
		dump.keys.each do |url|
			if response_codes.include? -1
				arr << [url,dump[url]['RESPONSE_CODE'], dump[url]['head_title'],dump[url]['head_description'],dump[url]['keywords']]
			else
				arr << [url,dump[url]['RESPONSE_CODE'], dump[url]['head_title'],dump[url]['head_description'],dump[url]['keywords']] if response_codes.include? dump[url]['RESPONSE_CODE']
			end
		end
		CSV.open(csv_output_path, "w") do |csv|
			csv << ["url", "head_title", "head_description", "keywords"]
			arr.each do |entry|
				csv << entry
			end
		end
	end
end