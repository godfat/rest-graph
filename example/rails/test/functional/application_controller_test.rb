
require 'test_helper'
require 'webmock'

WebMock.disable_net_connect!

class ApplicationControllerTest < ActionController::TestCase
  include WebMock

  def setup
    stub_request(:get, 'https://graph.facebook.com/me').
      to_return(:body => '{"error":"not authorized"}')
  end

  def teardown
    reset_webmock
  end

  def test_index
    get(:index)
    assert_response :redirect
    assert_equal(
      normalize_url(
        'https://graph.facebook.com/oauth/authorize?client_id=123&' \
        'scope=offline_access%2Cpublish_stream%2Cread_friendlists&' \
        'redirect_uri=http%3A%2F%2Ftest.host%2F'),
      normalize_url(assigns(:rest_graph_authorize_url)))
  end

  def test_iframe
    get(:iframe)
    assert_response :success
    assert_equal(
      normalize_url(
        'https://graph.facebook.com/oauth/authorize?client_id=123&' \
        'scope=publish_stream&'                                     \
        'redirect_uri=http%3A%2F%2Fapps.facebook.com%2F789%2Fiframe'),
      normalize_url((assigns(:rest_graph_authorize_url))))
  end

  def test_no_redirect
    get(:no_redirect)
    assert_response :success, 'XD'
  end

  def test_app_id
    get(:app_id)
    assert_response :success, 'zzz'
  end

  def test_url_for_canvas
    get(:url_for_canvas)
    assert_response :success, 'http://apps.facebook.com/789/application/index'
  end

  def test_url_for_standalone
    get(:url_for_standalone)
    assert_response :success, '/application/index'
  end
end
