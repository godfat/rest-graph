require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  def test_redirect
    get(:index)
    assert_response :success
  end
end
