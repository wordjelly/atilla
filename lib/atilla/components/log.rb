module Atilla::Components::Log
	def log_hierarchy
		["debug","info","error","fatal"]
	end

	def write_log(message,log_level="debug")
		allowed_index = log_hierarchy.index(self.opts["log_level"])
		#puts "allowed index #{allowed_index}"
		allowed = log_hierarchy[allowed_index..-1]
		#puts "allowed #{allowed}"
		#puts "incoming level #{log_level}"
		if allowed.include? log_level
			if self.opts["log_proc"]
				self.opts["log_proc"].call(message)
			end
			puts message
		else
			#puts "log not allowed"
		end
	end
end