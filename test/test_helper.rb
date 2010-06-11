ENV["RAILS_ENV"] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Función para utilizar en las pruebas de los métodos que requieren
  # autenticación
  def perform_auth(user = users(:administrator_user),
      organization = organizations(:default_organization))
    @request.host = "#{organization.prefix}.localhost.i"
    temp_controller, @controller = @controller, UsersController.new
    password = user.is_encrypted? ? PLAIN_PASSWORDS[user.user] : user.password

    if session[:user_id]
      get :logout, :id => User.find(session[:user_id]).user
      assert_nil session[:user_id]
      temp_controller.instance_eval { @auth_user = nil }
      assert_redirected_to :controller => :users, :action => :login
    end

    post :create_session, {:user =>
        {:user => user.user, :password => password}}, {}
    assert_redirected_to :controller => :welcome, :action => :index
    assert_not_nil session[:user_id]
    auth_user = User.find(session[:user_id])
    assert_not_nil auth_user
    assert_equal user.user, auth_user.user

    @controller = temp_controller
  end

  def get_test_parameter(parameter_name,
      organization = organizations(:default_organization))

    Parameter.find_parameter(organization.id, parameter_name)
  end

  def error_message_from_model(model, attribute, message, extra = {})
    ::ActiveRecord::Error.new(model, attribute, message, extra).message
  end

  def backup_file(file_name)
    if File.exists?(file_name)
      FileUtils.cp file_name, "#{TEMP_PATH}#{File.basename(file_name)}"
    end
  end
  
  def restore_file(file_name)
    if File.exists?("#{TEMP_PATH}#{File.basename(file_name)}")
      FileUtils.mv "#{TEMP_PATH}#{File.basename(file_name)}", file_name
    end
  end
end