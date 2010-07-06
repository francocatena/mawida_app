require 'test_helper'

# Pruebas para el controlador de grupos
class GroupsControllerTest < ActionController::TestCase
  fixtures :groups

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end

    # Intento de acceso con un usuario que no es administrador de grupos
    private_actions.each do |action|
      perform_auth(users(:administrator_second_user),
        organizations(:second_organization))

      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.insufficient_privileges'), flash[:notice]
    end
  end

  test 'list groups' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
    assert_select '#error_body', false
    assert_template 'groups/index'
  end

  test 'show group' do
    perform_auth
    get :show, :id => groups(:main_group).id
    assert_response :success
    assert_not_nil assigns(:group)
    assert_select '#error_body', false
    assert_template 'groups/show'
  end

  test 'new group' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:group)
    assert_select '#error_body', false
    assert_template 'groups/new'
  end

  test 'create group' do
    counts_array = ['Group.count', 'Organization.count',
      'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      perform_auth
      post :create, {
        :group => {
          :name => 'New group',
          :description => 'New group description',
          :admin_email => 'new_group@test.com',
          :send_notification_email => '1',
          :organizations_attributes => {
            :new_1 => {
              :name => 'New organization',
              :prefix => 'new-organization',
              :description => 'New organization description'
            }
          }
        }
      }
    end

    assert_equal Group.find_by_name('New group').id,
      Organization.find_by_prefix('new-organization').group_id
  end

  test 'create group without notification' do

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference ['Group.count', 'Organization.count'] do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        perform_auth
        post :create, {
          :group => {
            :name => 'New group',
            :description => 'New group description',
            :admin_email => 'new_group@test.com',
            :send_notification_email => '',
            :organizations_attributes => {
              :new_1 => {
                :name => 'New organization',
                :prefix => 'new-organization',
                :description => 'New organization description'
              }
            }
          }
        }
      end
    end

    assert_equal Group.find_by_name('New group').id,
      Organization.find_by_prefix('new-organization').group_id
  end

  test 'edit group' do
    perform_auth
    get :edit, :id => groups(:main_group).id
    assert_response :success
    assert_not_nil assigns(:group)
    assert_select '#error_body', false
    assert_template 'groups/edit'
  end

  test 'update group' do
    assert_no_difference ['Group.count', 'Organization.count'] do
      perform_auth
      put :update, {
        :id => groups(:main_group).id,
        :group => {
          :name => 'Updated group',
          :description => 'Updated group description',
          :admin_email => 'updated_group@test.com',
          :send_notification_email => '',
          :organizations_attributes => {
            organizations(:default_organization).id => {
              :id => organizations(:default_organization).id,
              :name => 'Updated default organization',
              :prefix => 'default-testing-organization',
              :description => 'Updated default organization description'
            },
            organizations(:second_organization).id => {
              :id => organizations(:second_organization).id,
              :name => 'Updated second organization',
              :prefix => 'second-testing-organization',
              :description => 'Updated second organization description'
            }
          }
        }
      }
    end
    
    assert_redirected_to groups_path
    assert_not_nil assigns(:group)
    assert_equal 'Updated group', assigns(:group).name
    assert_equal 'Updated default organization',
      Organization.find(organizations(:default_organization).id).name
  end

  test 'destroy group' do
    perform_auth
    assert_difference 'Group.count', -1 do
      delete :destroy, :id => groups(:main_group).id
    end

    assert_redirected_to groups_path
  end
end