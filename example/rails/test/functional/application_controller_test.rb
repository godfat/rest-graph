
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
        'scope=&' \
        'redirect_uri=http%3A%2F%2Ftest.host%2F'),
      normalize_url(assigns(:rest_graph_authorize_url)))
  end

  def test_canvas
    get(:canvas)
    assert_response :success
    assert_equal(
      normalize_url(
        'https://graph.facebook.com/oauth/authorize?client_id=123&' \
        'scope=publish_stream&'                                     \
        'redirect_uri=http%3A%2F%2Fapps.facebook.com%2Fcan%2Fcanvas'),
      normalize_url((assigns(:rest_graph_authorize_url))))
  end

  def test_diff_canvas
    get(:diff_canvas)
    assert_response :success
    assert_equal(
      normalize_url(
        'https://graph.facebook.com/oauth/authorize?client_id=123&' \
        'scope=email&'                                              \
        'redirect_uri=http%3A%2F%2Fapps.facebook.com%2FToT%2Fdiff_canvas'),
      normalize_url((assigns(:rest_graph_authorize_url))))
  end

  def test_options
    get(:options)
    assert_response :redirect
    assert_equal(
      normalize_url(
        'https://graph.facebook.com/oauth/authorize?client_id=123&' \
        'scope=bogus&'                                              \
        'redirect_uri=http%3A%2F%2Ftest.host%2Foptions'),
      normalize_url((assigns(:rest_graph_authorize_url))))
  end

  def test_no_auto
    get(:no_auto)
    assert_response :success
    assert_equal 'XD', @response.body
  end

  def test_app_id
    get(:diff_app_id)
    assert_response :success
    assert_equal 'zzz', @response.body
  end
end
