require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:google, info: { email: 'user@example.org' })
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google]
    request.env['omniauth.params'] = { back_url: 'http://example.org' }
  end

  def teardown
    OmniAuth.config.mock_auth[:google] = nil
  end

  test 'redirects to approval form when user is not found' do
    User.stub :exists?, false do
      get :create, provider: 'google'
    end

    assert_redirected_to new_approval_url
  end

  test 'sets the session with the user when already has an account' do
    User.stub :exists?, true do
      get :create, provider: 'google'
    end

    assert_equal session[:user_id], 'user@example.org'
    assert_redirected_to 'http://example.org'
  end

  test 'returns a 400 Bad Request error when the back url param is not set' do
    request.env['omniauth.params'] = { }

    get :create, provider: 'google'

    assert_response :bad_request
    assert_equal JSON.parse(response.body)['error'], 'back url is missing'
  end

  test 'returns the current session when the user has logged in' do
    session[:user_id] = 'user@example.org'

    get :current

    assert_equal JSON.parse(response.body)['email'], 'user@example.org'
  end

  test 'returns a 401 Unauthorized status  when session is not available' do
    session[:user_id] = nil

    get :current

    assert_response :unauthorized
  end

  test 'destroys the active session when the user logs out' do
    get :destroy

    assert_response :ok
    assert_equal session[:user_id], nil
  end
end