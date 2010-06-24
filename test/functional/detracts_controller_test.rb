require 'test_helper'

# Pruebas para el controlador de detractores
class DetractsControllerTest < ActionController::TestCase
  fixtures :detracts, :users, :organizations

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :new, :create]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list detracts' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_select '#error_body', false
    assert_template 'detracts/index'
  end

  test 'list detracts with search' do
    perform_auth
    get :index, :search => {:query => 'manager', :columns => ['user', 'name']}
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size
    assert_select '#error_body', false
    assert_template 'detracts/index'
  end

  test 'new detract when search match only one result' do
    perform_auth
    get :index, :search => {:query => 'admin', :columns => ['user', 'name']}
    assert_redirected_to new_detract_path(
      :detract => {:user_id => users(:administrator_user).id})
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size
  end

  test 'show detract whit no approval privilege' do
    user = User.find users(:bare_user).id
    
    perform_auth(user)
    get :index
    assert_redirected_to :action => :show, :id => user.detracts.last
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size
  end

  test 'show detract whit no approval privilege as audited without detracts' do
    user = User.find users(:audited_user).id

    perform_auth(user)
    get :show, :id => user.detracts.last
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:detracts)
    assert assigns(:detracts).empty?
    assert_select '#error_body', false
    assert_match Regexp.new(I18n.t(:'detract.without_detract')), @response.body
    assert_template 'detracts/show'
  end

  test 'show detract' do
    perform_auth
    get :show, :id => detracts(
      :adequate_for_administrator_in_default_organization).id
    assert_response :success
    assert_not_nil assigns(:detract)
    assert_select '#error_body', false
    assert_template 'detracts/show'
  end

  test 'new detract' do
    perform_auth
    get :new, :detract => {:user_id => users(:administrator_user).id}
    assert_response :success
    assert_not_nil assigns(:detract)
    assert_select '#error_body', false
    assert_template 'detracts/new'
  end

  test 'create detract' do
    assert_difference 'Detract.count' do
      perform_auth
      post :create, {
        :detract => {
          :value => '0.8',
          :observations => 'New observations',
          :user => users(:administrator_user),
          :organization => organizations(:default_organization)
        }
      }
    end
  end

  test 'show last detracts' do
    perform_auth
    get :show_last_detracts, :id => users(:administrator_user).id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:detracts)
    assert !assigns(:detracts).empty?
    assert_select '#error_body', false
    assert_template 'detracts/_show_last_detracts'
  end

  test 'show last detracts with no approval privilege' do
    perform_auth(users(:bare_user))
    get :show_last_detracts, :id => users(:bare_user).id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:detracts)
    assert !assigns(:detracts).empty?
    assert_select '#error_body', false
    assert_template 'detracts/_show_last_detracts'
  end

  test 'show last detracts from not related user with no approval privilege' do
    perform_auth(users(:bare_user))
    get :show_last_detracts, :id => users(:administrator_user).id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:detracts)
    assert assigns(:detracts).empty?
    assert_select '#error_body', false
    assert_template 'detracts/_show_last_detracts'
  end
end