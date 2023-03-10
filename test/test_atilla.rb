# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test

  # so given directory -> extract to one file.
  # 

=begin
  def test_google_output_parser
      parser = Atilla::GoogleSearchConsoleParser.new("/home/bhargav/Github/atilla/sensitive_resources/404.csv","404")
      parser.parse_csv
  end
=end

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
  def test_eyecove
    Atilla::Es.delete_index("crawl_responses")
    
    Atilla::Es.create_index("crawl_responses")
      
    crawler = Atilla::Crawler.new("https://eyecove.in/",[],{"headers" => {"Cache-Purge" => true, "Content-Type" => "text/html", "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36", "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    urls = JSON.parse(IO.read(crawler.get_crawl_output_dir_path + "/all_crawled.json"))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")

  end
=end


=begin
  def test_crawls_dummy_url
    Atilla::Es.delete_index("crawl_responses")
    
    Atilla::Es.create_index("crawl_responses")
      
    #"Cache-Purge" => true
    crawler = Atilla::Crawler.new("http://pathofast-local",[],{"headers" => {"Cache-Purge" => true, "Content-Type" => "text/html", "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Safari/537.36", "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"},"params" => {}, "output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})

    crawler.run

    urls = JSON.parse(IO.read(crawler.get_crawl_output_dir_path + "/all_crawled.json"))
      
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

    output_file_path = Atilla::GoogleSearchConsoleParser.parse_directory("/home/bhargav/Github/atilla/sensitive_resources")

    Atilla::Es.delete_index("crawl_responses")
    
    Atilla::Es.create_index("crawl_responses")

    crawler = Atilla::Crawler.new("http://pathofast-local",[],{"headers" => {"Cache-Purge" => true},"params" => {}, "urls_file" => output_file_path,"urls_file_limit" => nil ,"output_path" => (__FILE__.split(/\//)[0..-3].join("/") + "/output")})
    crawler.run


    urls = JSON.parse(IO.read(crawler.get_crawl_output_dir_path + "/all_crawled.json"))
      
    Atilla::Es.bulk_index(urls,"crawl_responses")

  end

end
