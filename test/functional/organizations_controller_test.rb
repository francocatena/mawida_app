require 'test_helper'

# Pruebas para el controlador de organizaciones
class OrganizationsControllerTest < ActionController::TestCase
  fixtures :organizations, :image_models, :business_units

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :new, :edit, :create, :update, :destroy,
      :edit_business_units, :update_business_units]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:alert]
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list organizations' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
    # Sólo la organización del grupo autenticado
    assert_equal 1, assigns(:organizations).size
    assert_select '#error_body', false
    assert_template 'organizations/index'
  end

  test 'show organization' do
    perform_auth
    get :show, :id => organizations(:default_organization).id
    assert_response :success
    assert_not_nil assigns(:organization)
    assert_select '#error_body', false
    assert_template 'organizations/show'
  end

  test 'new organization' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:organization)
    assert_select '#error_body', false
    assert_template 'organizations/new'
  end

  test 'create organization' do
    user = User.find users(:administrator_user).id

    perform_auth user

    assert_difference ['Organization.count', 'user.organizations.count'] do
      post :create, {
        :organization => {
          :name => 'New organization',
          :prefix => 'new-prefix',
          :description => 'New description',
          :group_id => groups(:main_group).id,
          :image_model_id => image_models(:image_one).id
        }
      }
    end

    assert_equal groups(:main_group).id,
      Organization.find_by_prefix('new-prefix').group_id
  end

  test 'create organization with wrong group' do
    user = User.find users(:administrator_user).id

    perform_auth user

    assert_difference ['Organization.count', 'user.organizations.count'] do
      post :create, {
        :organization => {
          :name => 'New organization',
          :prefix => 'new-prefix',
          :description => 'New description',
          :group_id => groups(:second_group).id,
          :image_model_id => image_models(:image_one).id
        }
      }
    end

    # El grupo debe ser el mismo que el de la organización autenticada
    assert_equal groups(:main_group).id,
      Organization.find_by_prefix('new-prefix').group_id
  end

  test 'edit organization' do
    perform_auth
    get :edit, :id => organizations(:default_organization).id
    assert_response :success
    assert_not_nil assigns(:organization)
    assert_select '#error_body', false
    assert_template 'organizations/edit'
  end

  test 'update organization' do
    perform_auth
    put :update, {
      :id => organizations(:default_organization).id,
      :organization => {
        :name => 'Updated organization',
        :description => 'Updated description',
        :image_model_id => image_models(:image_one).id
      }
    }

    assert_redirected_to organizations_path
    assert_not_nil assigns(:organization)
    assert_equal 'Updated organization', assigns(:organization).name
  end

  test 'destroy organization' do
    perform_auth(users(:administrator_second_user),
      organizations(:second_organization))
    
    assert_difference ['Organization.count', 'BusinessUnitType.count'], -1 do
      delete :destroy, :id => organizations(:second_organization).id
    end
    
    assert_redirected_to organizations_path
  end
end