# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test

=begin
  def test_rebuilds_url_params
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"params" => {"nocache" => true}})
    puts crawler.append_params("http://192.168.1.2?dog=cat")
  end
=end

  def test_crawls_dummy_url
    crawler = Atilla::Crawler.new("http://192.168.1.2",[],{"params" => {"nocache" => true}})
    puts crawler.append_url("http://192.168.1.2?dog=cat")
    #crawler.run
  end

end
