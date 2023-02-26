# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test

=begin
  def test_rebuilds_url_params
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"params" => {"nocache" => true}})
    puts crawler.append_params("http://192.168.1.2?dog=cat")
  end
=end


  def test_index_file
    
    urls = JSON.parse(IO.read(""))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")
  end

=begin
  def test_crawls_dummy_url
    #Atilla::Es.delete_index("crawl_responses")
    
    #Atilla::Es.create_index("crawl_responses")
    crawler = Atilla::Crawler.new("http://192.168.43.91",[],{"params" => {"nocache" => true}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    urls = JSON.parse(IO.read((__FILE__.split(/\//)[0..-3].join("/") + "/output/#{crawler.output_file_path_prefix}-crawl.json")))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")


  end
=end

end
