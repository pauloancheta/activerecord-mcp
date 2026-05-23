# frozen_string_literal: true

require "test_helper"

class TokenValidatorTest < ActiveSupport::TestCase
  def app
    inner = ->(_env) { [200, { "Content-Type" => "application/json" }, ["ok"]] }
    RailsMcp::Auth::TokenValidator.new(inner)
  end

  test "allows OPTIONS requests without token" do
    status, = app.call(env("OPTIONS", "/mcp"))
    assert_equal 200, status
  end

  test "allows /.well-known/ without token" do
    status, = app.call(env("GET", "/.well-known/oauth-authorization-server"))
    assert_equal 200, status
  end

  test "rejects request with no Authorization header" do
    status, _, body = app.call(env("POST", "/mcp"))
    assert_equal 401, status
    assert_match "Bearer token required", body.join
  end

  test "rejects invalid token" do
    status, _, body = app.call(env("POST", "/mcp", token: "bogus"))
    assert_equal 401, status
    assert_match "Invalid or expired token", body.join
  end

  test "rejects expired token" do
    token = create_valid_token(expires_in: -1)
    status, = app.call(env("POST", "/mcp", token: token.token))
    assert_equal 401, status
  end

  test "rejects revoked token" do
    token = create_valid_token
    token.revoke
    status, = app.call(env("POST", "/mcp", token: token.token))
    assert_equal 401, status
  end

  test "passes valid token through and sets env key" do
    token = create_valid_token
    rack_env = env("POST", "/mcp", token: token.token)
    status, = app.call(rack_env)
    assert_equal 200, status
    assert_equal token.id, rack_env["rails_mcp.access_token"].id
  end

  private

  def env(method, path, token: nil)
    e = Rack::MockRequest.env_for(path, method: method)
    e["HTTP_AUTHORIZATION"] = "Bearer #{token}" if token
    e
  end

  def create_valid_token(expires_in: 3600)
    app_record = Doorkeeper::Application.create!(
      name: "test-#{SecureRandom.hex(4)}",
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      confidential: false
    )
    Doorkeeper::AccessToken.create!(application: app_record, expires_in: expires_in)
  end
end
