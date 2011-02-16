
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
begin
  require 'rails/test_help'
rescue LoadError # for rails2
  require 'test_help'
end

class ActiveSupport::TestCase
  def normalize_query query
    '?' + query[1..-1].split('&').sort.join('&')
  end

  def normalize_url url
    url.sub(/\?.+/){ |query| normalize_query(query) }
  end
end
