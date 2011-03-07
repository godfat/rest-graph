
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
begin
  require 'rails/test_help'
rescue LoadError # for rails2
  require 'test_help'
end

class ActiveSupport::TestCase
  def normalize_query query, amp='&'
    '?' + query[1..-1].split(amp).sort.join(amp)
  end

  def normalize_url url, amp='&'
    url.sub(/\?.+/){ |query| normalize_query(query, amp) }
  end
end
