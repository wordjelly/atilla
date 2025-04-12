module Atilla::Components::ImageExtractor


	def get_sorted_images_by_size(root_el, doc, base_url = nil)
	  images = doc.css("#{root_el} img")

	  image_data = images.map do |img|
	    # Check if parent <a> exists and points to / or root domain
	    a_tag = img.ancestors('a').first
	    href = a_tag&.[]('href')

	    next if href && (
	      href.strip == '/' ||
	      (begin
	         uri = URI.join(base_url || '', href)
	         uri.path == '/' && uri.query.nil? && uri.fragment.nil?
	       rescue URI::InvalidURIError
	         false
	       end)
	    )

	    width = img['width']&.to_i
	    height = img['height']&.to_i

	    # Fallback to style attribute
	    if (!width || width == 0 || !height || height == 0) && img['style']
	      style = img['style']
	      width_match = style.match(/width\s*:\s*(\d+)px/i)
	      height_match = style.match(/height\s*:\s*(\d+)px/i)
	      width ||= width_match[1].to_i if width_match
	      height ||= height_match[1].to_i if height_match
	    end

	    {
	      element: img,
	      src: img['src'],
	      width: width || 0,
	      height: height || 0,
	      size: (width || 0) * (height || 0)
	    }
	  end.compact

	  sorted = image_data.sort_by { |img| -img[:size] }
	  sorted.map { |img| img[:src] }
	end

	def fix_newline_in_json(json_str)
		json_str.gsub(/"(?:[^"\\]|\\.)*"/) do |match|
		  match.gsub(/\n/, '')  # or `.gsub(/[\r\n]+/, '')` for both CRLF/LF
		end
	end

	def get_ld_json_images(doc)
		images = []
		doc.css('script[type="application/ld+json"]').each do |k|
			txt = fix_newline_in_json(k.text)
			json = JSON.parse(txt)
			images << json['image'] unless json['image'].blank?
		end
		images
	end

	# how do you manage to ignore them?
	# the best image -. 
	def get_og_images(doc)
		image_tags = ["og:image","og:image:url","og:image:secure_url"]
		images = []
		image_tags.map{|name|
			doc.css("meta[name='#{name}']").each do |l|
				images << l['content']
			end
		}
		images
	end

	# expand on this later to get product markup images using ldjson
	# doc here is nokogigir doc..
	def get_best_image(meta_inspector_page,url,response,doc,host)
		images = []
		images << get_og_images(doc)
		images << get_ld_json_images(doc)
		images << get_sorted_images_by_size("body",doc, host)
		images.flatten!
		images.uniq!
		images.map!{|r|
			unless r =~ /#{Regexp.escape(host)}/
				host + r
			else
				r
			end
		}
		return images
	end
end