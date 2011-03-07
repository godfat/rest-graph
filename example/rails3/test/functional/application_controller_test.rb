
require 'test_helper'
require 'webmock'

WebMock.disable_net_connect!

class ApplicationControllerTest < ActionController::TestCase
  include WebMock::API

  def setup
    body = rand(2) == 0 ? '{"error":{"type":"OAuthException"}}' :
                          '{"error_code":104}'

    stub_request(:get, 'https://graph.facebook.com/me').
      to_return(:body => body)
  end

  def teardown
    WebMock.reset!
  end

  def assert_url expected
    assert_equal(expected, normalize_url(assigns(:rest_graph_authorize_url)))
    if @response.status == 200 # js redirect
      assert_equal(
        expected,
        normalize_url(
          @response.body.match(/window\.top\.location\.href = '(.+?)'/)[1]))

      assert_equal(
        CGI.escapeHTML(expected),
        normalize_url(
          @response.body.match(/content="0;url=(.+?)"/)[1], '&amp;'))

      assert_equal(
        CGI.escapeHTML(expected),
        normalize_url(
          @response.body.match(/<a href="(.+?)" target="_top">/)[1], '&amp;'))
    end
  end

  def test_index
    get(:index)
    assert_response :redirect

    url = normalize_url(
      'https://graph.facebook.com/oauth/authorize?client_id=123&' \
      'scope=&redirect_uri=http%3A%2F%2Ftest.host%2F')

    assert_url(url)
  end

  def test_canvas
    get(:canvas)
    assert_response :success

    url = normalize_url(
      'https://graph.facebook.com/oauth/authorize?client_id=123&' \
      'scope=publish_stream&'                                     \
      'redirect_uri=http%3A%2F%2Fapps.facebook.com%2Fcan%2Fcanvas')

    assert_url(url)
  end

  def test_diff_canvas
    get(:diff_canvas)
    assert_response :success

    url = normalize_url(
      'https://graph.facebook.com/oauth/authorize?client_id=123&' \
      'scope=email&'                                              \
      'redirect_uri=http%3A%2F%2Fapps.facebook.com%2FToT%2Fdiff_canvas')

    assert_url(url)
  end

  def test_iframe_canvas
    get(:iframe_canvas)
    assert_response :success

    url = normalize_url(
      'https://graph.facebook.com/oauth/authorize?client_id=123&' \
      'scope=&'                                                   \
      'redirect_uri=http%3A%2F%2Fapps.facebook.com%2Fzzz%2Fiframe_canvas')

    assert_url(url)
  end

  def test_options
    get(:options)
    assert_response :redirect

    url = normalize_url(
      'https://graph.facebook.com/oauth/authorize?client_id=123&' \
      'scope=bogus&'                                              \
      'redirect_uri=http%3A%2F%2Ftest.host%2Foptions')

    assert_url(url)
  end

  def test_protected
    assert_nil @controller.public_methods.find{ |m| m.to_s =~ /^rest_graph/ }
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

  def test_cache
    WebMock.reset!
    stub_request(:get, 'https://graph.facebook.com/cache').
      to_return(:body => '{"message":"ok"}')

    get(:cache)
    assert_response :success
    assert_equal '{"message":"ok"}', @response.body
  end

  def test_handler
    WebMock.reset!
    stub_request(:get, 'https://graph.facebook.com/me?access_token=aloha').
      to_return(:body => '["snowman"]')

    Rails.cache[:fbs] = RestGraph.new(:access_token => 'aloha').fbs
    get(:handler_)
    assert_response :success
    assert_equal '["snowman"]', @response.body
  ensure
    Rails.cache.clear
  end

  def test_session
    WebMock.reset!
    stub_request(:get, 'https://graph.facebook.com/me?access_token=wozilla').
      to_return(:body => '["fireball"]')

    @request.session[RestGraph::RailsUtil.rest_graph_storage_key] =
      RestGraph.new(:access_token => 'wozilla').fbs

    get(:session_)
    assert_response :success
    assert_equal '["fireball"]', @response.body
  end

  def test_cookies
    WebMock.reset!
    stub_request(:get, 'https://graph.facebook.com/me?access_token=blizzard').
      to_return(:body => '["yeti"]')

    @request.cookies[RestGraph::RailsUtil.rest_graph_storage_key] =
      RestGraph.new(:access_token => 'blizzard').fbs

    get(:cookies_)
    assert_response :success
    assert_equal '["yeti"]', @response.body
  end

  def test_error
    get(:error)
  rescue => e
    assert_equal RestGraph::Error, e.class
  end

  def test_reinitailize
    get(:reinitialize)
    assert_response :success
    assert_equal [nil, {'a' => 'b'}], YAML.load(@response.body)
  end

  def test_helper
    get(:helper)
    assert_response :success
    assert_equal RestGraph.default_app_id, @response.body.strip
  end
end
