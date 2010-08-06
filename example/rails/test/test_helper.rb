
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  def normalize_query query
    '?' + query[1..-1].split('&').sort.join('&')
  end

  def normalize_url url
    url.sub(/\?.+/){ |query| normalize_query(query) }
  end
end
