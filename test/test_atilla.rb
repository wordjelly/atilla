# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test

=begin
  def test_rebuilds_url_params
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"params" => {"nocache" => true}})
    puts crawler.append_params("http://192.168.1.2?dog=cat")
  end
=end

=begin
  def test_index_file
    
    urls = JSON.parse(IO.read("/home/bhargav/Github/atilla/output/https:--eyecove.in--2023-03-01T09:31:28.107+05:30-crawl.json"))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")
  end
=end

=begin
  def test_crawls_dummy_url
    Atilla::Es.delete_index("crawl_responses")
    
    Atilla::Es.create_index("crawl_responses")
    
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    urls = JSON.parse(IO.read((__FILE__.split(/\//)[0..-3].join("/") + "/output/#{crawler.output_file_path_prefix}-crawl.json")))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")

  end
=end
  
=begin
  def test_segments_url_outputs

    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    #write_code_wise_urls(urls_hash)
    urls_hash = JSON.parse(IO.read("/home/bhargav/Github/atilla/output/http:--192.168.1.2--2023-03-01T13:23:26.583+05:30-crawl.json"))
    crawler.write_code_wise_urls(urls_hash)

  end
=end

  def test_crawls_files_in_url_list
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "urls_file" => "/home/bhargav/Github/atilla/output/http:--192.168.1.2--2023-03-01T15:10:18.444+05:30/500.json", "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
      crawler.run
  end

end
