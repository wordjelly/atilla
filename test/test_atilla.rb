# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test

=begin
  def test_crawls_url

    Atilla::Es.wipe_index("crawl_responses")
    
    crawler = Atilla::Crawler.new("http://local/",[],{"headers" => {"Cache-Purge" => true} , "requests_per_second" => 100,  "params" => {},"save_output" => true,   "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    Atilla::Es.bulk_index(crawler.get_all_crawled_urls,"crawl_responses")

  end
=end
  
=begin
  def test_crawls_robotstxt
    response = Typhoeus.get("http://ben.balter.com/robots.txt", {:follow_location => true})
    puts response.code.to_s
    puts "body is #{response.body.to_s}"
    parser = Robotstxt::Parser.new("dog",response.body)
    puts parser.sitemaps.to_s
    puts parser.allowed?("http://ben.balter.com/")
    puts parser.allowed?("/404.html")
  end
=end

=begin
  def test_metainspect
    page = MetaInspector.new("http://localhost:5000", :document => "<html></html>")
    puts page.title
  end
=end

=begin
  def test_crawls_sitemap
    crawler = Atilla::Crawler.new("http://ben.balter.com/",[],{"save_output" => true, "headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    crawler.run    
  end
=end
  
  # enqueue and dequeue are independent functions.

  def test_crawls_url_patterns
    crawler = Atilla::Crawler.new("http://localhost:4000",[],{"save_output" => true, "requests_per_second" => 100, "sitemap_urls" => ["http://localhost:4000/normal_sitemap.xml"], "headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    crawler.crawl_sitemap
    crawler.run
  end


=begin
  def test_crawls_url

    crawler = Atilla::Crawler.new("https://www.crawler-test.com/",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

  end
=end

=begin
  def test_crawls_files_in_url_list

    combined_urls_list_file_path = Atilla::GoogleSearchConsoleParser.parse_directory("/home/bhargav/Github/atilla/sensitive_resources")

    crawler = Atilla::Crawler.new("http://local",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "urls_file" => combined_urls_list_file_path,"urls_file_limit" => nil ,"output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    
    crawler.run
   
  end

  def test_indexes_data_to_elasticsearch
    
    crawler = Atilla::Crawler.new("http://local",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    Atilla::Es.wipe_index("crawl_responses")
  
    Atilla::Es.bulk_index(crawler.get_all_crawled_urls,"crawl_responses")
  
  end
=end

end
