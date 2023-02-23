# frozen_string_literal: true

require "test_helper"

class TestAtilla < Minitest::Test
  def test_crawls_dummy_url
    crawler = Atilla::Crawler.new("http://192.168.1.3",[],{"params" => {"nocache" => true}})
    crawler.run
  end
end
