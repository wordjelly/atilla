class Atilla::DataStores::FileStore
	def create_or_update(page,url)
	end

	def get(url)
	end

	################ LEGACY HELPERS ###########
	private
	def output_file_path_prefix
		self.host.gsub(/\//,'-') + "-#{self.crawl_started_at.strftime("%Y-%m-%dT%H:%M:%S.%L%:z")}"
	end

	def get_crawl_output_dir_path
		self.opts["output_path"] + "/#{output_file_path_prefix}"
	end

	def create_crawl_output_dir
		return unless self.opts["save_output"] == true
		if self.opts["output_path"].blank?
			raise "please specify an output path for the directory that will hold the crawl results"
		end
		FileUtils.mkdir_p(self.opts["output_path"] + "/#{output_file_path_prefix}")
	end

end