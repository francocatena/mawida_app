require 'test_helper'

# Pruebas para el controlador de perfiles
class RolesControllerTest < ActionController::TestCase
  fixtures :roles, :users

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      params: {
        id: roles(:admin_role).to_param
      }
    }
    public_actions = []
    private_actions = [
      [:get, :index, {}],
      [:get, :show, id_param],
      [:get, :new, {}],
      [:get, :edit, id_param],
      [:post, :create, {}],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      options = action.pop

      send *action, **options
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list roles' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
    assert_template 'roles/index'
  end

  test 'show role' do
    login
    get :show, params: { id: roles(:admin_role).id }
    assert_response :success
    assert_not_nil assigns(:role)
    assert_template 'roles/show'
  end

  test 'new role' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:role)
    assert_template 'roles/new'
  end

  test 'new role as JS' do
    login
    get :new, xhr: true, as: :js
    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end

  test 'create role' do
    assert_difference ['Role.count', 'Privilege.count'] do
      login
      post :create, params: {
        role: {
          name: 'New role',
          role_type: Role::TYPES[:admin],
          privileges_attributes: [
            {
              module: ALLOWED_MODULES_BY_TYPE[:admin].first.to_s,
              approval: true,
              erase: true,
              modify: true,
              read: true
            }
          ]
        }
      }
    end
  end

  test 'edit role' do
    login
    get :edit, params: { id: roles(:admin_role).id }
    assert_response :success
    assert_not_nil assigns(:role)
    assert_template 'roles/edit'
  end

  test 'edit role as JS' do
    login
    get :edit, params: { id: roles(:admin_role).id }, xhr: true, as: :js
    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end

  test 'update role' do
    privilege = Privilege.find(privileges(:admin_administration_settings).id)
    assert privilege.approval

    assert_no_difference ['Role.count', 'Privilege.count'] do
      login
      patch :update, params: {
        id: roles(:admin_role).id,
        role: {
          name: 'Updated role',
          role_type: Role::TYPES[:admin],
          privileges_attributes: [
            {
              id: privilege.id,
              module: privilege.module,
              approval: false,
              erase: false,
              modify: false,
              read: false
            }
          ]
        }
      }
    end

    assert_redirected_to roles_url
    assert_not_nil assigns(:role)
    assert_equal 'Updated role', assigns(:role).name
    assert !assigns(:role).privileges.find(privilege.id).approval
  end

  test 'destroy role' do
    login
    assert_difference 'Role.count', -1 do
      delete :destroy, params: { id: roles(:auditor_role).id }
    end

    assert_redirected_to roles_url
  end
end
