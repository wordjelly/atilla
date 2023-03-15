# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test


  def test_crawls_url

    crawler = Atilla::Crawler.new("https://www.crawler-test.com/",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

  end

=begin
  def test_crawls_files_in_url_list

    combined_urls_list_file_path = Atilla::GoogleSearchConsoleParser.parse_directory("/home/bhargav/Github/atilla/sensitive_resources")

    crawler = Atilla::Crawler.new("http://pathofast-local",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "urls_file" => combined_urls_list_file_path,"urls_file_limit" => nil ,"output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    
    crawler.run
   
  end

  def test_indexes_data_to_elasticsearch
    
    crawler = Atilla::Crawler.new("http://pathofast-local",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    Atilla::Es.wipe_index("crawl_responses")
  
    Atilla::Es.bulk_index(crawler.get_all_crawled_urls,"crawl_responses")
  
  end
=end

end
