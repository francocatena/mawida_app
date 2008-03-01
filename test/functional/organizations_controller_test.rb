require 'test_helper'

# Pruebas para el controlador de organizaciones
class OrganizationsControllerTest < ActionController::TestCase
  fixtures :organizations, :image_models, :business_units

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list organizations' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
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
    counts_array = ['Organization.count', 'BusinessUnit.count',
      'user.organizations.count']

    perform_auth user

    assert_difference counts_array do
      post :create, {
        :organization => {
          :name => 'New organization',
          :prefix => 'new-prefix',
          :description => 'New description',
          :image_model_id => image_models(:image_one).id,
          :business_units_attributes => {
            :new_1 => {
              :name => 'new business_unit 1',
              :business_unit_type => BusinessUnit::TYPES[:cycle]
            }
          }
        }
      }
    end
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
        :image_model_id => image_models(:image_one).id,
        :business_units_attributes => {
          business_units(:business_unit_one).id => {
            :id => business_units(:business_unit_one).id,
            :name => 'Updated business units',
            :business_unit_type => BusinessUnit::TYPES[:cycle]
          }
        }
      }
    }

    business_unit = BusinessUnit.find business_units(:business_unit_one).id

    assert_redirected_to organizations_path
    assert_not_nil assigns(:organization)
    assert_equal 'Updated organization', assigns(:organization).name
    assert_equal 'Updated business units', business_unit.name
  end

  test 'destroy organization' do
    perform_auth
    
    assert_difference ['Organization.count', 'BusinessUnit.count'], -1 do
      delete :destroy, :id => organizations(:second_organization).id
    end
    
    assert_redirected_to organizations_path
  end
end