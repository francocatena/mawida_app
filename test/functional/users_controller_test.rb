require 'test_helper'

# Pruebas para el controlador de usuarios
class UsersControllerTest < ActionController::TestCase
  fixtures :users, :roles, :organizations

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = [:login]
    @private_actions = [:index, :show, :new, :edit, :create, :update, :destroy,
      :blank_password, :change_password, :change_personal_data, :logout]
    @request.host = "#{organizations(:default_organization).prefix}.localhost.i"
  end

  def teardown
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert [I18n.t(:'message.must_be_authenticated'),
        I18n.t(:'user.confirmation_link_invalid')].include?(flash[:notice])
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  # Prueba que no pueda autenticarse un usuario que no es válido
  test 'invalid user and password attempt' do
    assert_difference 'ErrorRecord.count' do
      post :login,
        :user => { :user => 'someone', :password => 'without authorization' }

      error_record = ErrorRecord.find(:first,
        :conditions => ['data LIKE :data', {:data => '%someone%'}],
        :order => 'created_at DESC')
      assert_kind_of ErrorRecord, error_record
      assert_response :success
      # en div#notice se leen los mensajes de flash[]
      assert_select '#notice p', I18n.t(:'message.invalid_user_or_password')
    end
  end

  test 'invalid password attempt' do
    assert_difference 'ErrorRecord.count' do
      post :login,
        :user => {
          :user => users(:administrator_user).user,
          :password => 'wrong password'
        }
      error_record = ErrorRecord.find(:first,
        :conditions => {
          :user_id => users(:administrator_user).id,
          :error => ErrorRecord::ERRORS[:on_login]
        },
        :order => 'created_at DESC')
      assert_kind_of ErrorRecord, error_record
      assert_response :success
      # en div#notice se leen los mensajes de flash[]
      assert_select '#notice p', I18n.t(:'message.invalid_user_or_password')
    end
  end

  test 'disabled user attempt' do
    assert_difference 'ErrorRecord.count' do
      post :login,
        :user => {
          :user => users(:disabled_user).user,
          :password => PLAIN_PASSWORDS[users(:disabled_user).user]
        }
      error_record = ErrorRecord.find(:first,
        :conditions => {
          :user_id => users(:disabled_user).id,
          :error => ErrorRecord::ERRORS[:on_login]
        },
        :order => 'created_at DESC')
      assert_kind_of ErrorRecord, error_record
      assert_response :success
      # en div#notice se leen los mensajes de flash[]
      assert_select '#notice p', I18n.t(:'message.invalid_user_or_password')
    end
  end

  test 'excede maximun number off wrong attempts' do
    user = User.find users(:administrator_user).id
    max_attempts = user.get_parameter(:security_attempts_count).to_i

    assert_difference 'ErrorRecord.count', max_attempts + 1 do
      max_attempts.times do
        post :login,
          :user => { :user => user.user, :password => 'wrong password' }
        error_record = ErrorRecord.find(:first,
          :conditions => {
            :user_id => user.id,
            :error => ErrorRecord::ERRORS[:on_login]
          },
          :order => 'created_at DESC')
        assert_kind_of ErrorRecord, error_record
        assert_response :success
        # en div#notice se leen los mensajes de flash[]
        assert_select '#notice p', I18n.t(:'message.invalid_user_or_password')
      end

      assert_response :success
      error_record = ErrorRecord.find(:first,
          :conditions => {
            :user_id => users(:administrator_user).id,
            :error => ErrorRecord::ERRORS[:user_disabled]
          },
          :order => 'created_at DESC')
      assert_kind_of ErrorRecord, error_record
      user = User.find users(:administrator_user).id
      assert_equal max_attempts, user.failed_attempts
      assert_equal false, user.enable?
    end
  end

  test 'login without organization' do
    @request.host = 'localhost.i'
    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }
    assert_response :success
    # en div#notice se leen los mensajes de flash[]
    assert_select '#no_organization', I18n.t(:'message.no_organization')
  end

  test 'login sucesfully' do
    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }

    assert_redirected_to :controller => :welcome, :action => :index
    login_record = LoginRecord.find(:first, :conditions => {
        :user_id => users(:administrator_user).id,
        :organization_id => organizations(:default_organization).id
      })
    assert_kind_of LoginRecord, login_record
  end

  test 'login with hashed password' do
    assert_difference 'ErrorRecord.count' do
      post :login,
        :user => {
          :user => users(:administrator_user).user,
          :password => users(:administrator_user).password
        }
      error_record = ErrorRecord.first(
        :conditions => {
          :user_id => users(:administrator_user).id,
          :error => ErrorRecord::ERRORS[:on_login]
        },
        :order => 'created_at DESC')
      assert_kind_of ErrorRecord, error_record
      assert_response :success
      # en div#notice se leen los mensajes de flash[]
      assert_select '#notice p', I18n.t(:'message.invalid_user_or_password')
    end
  end

  test 'expired user attempt' do
    user = User.find users(:expired_user).id
    # TODO: eliminar cuando se corriga el error en JRuby que no permite que
    # este atributo se cargue desde los fixtures
    user.update_attribute :last_access,
      get_test_parameter(:security_acount_expire_time).to_i.days.ago.yesterday

    assert user.enable?
    post :login,
      :user => {
        :user => users(:expired_user).user,
        :password => PLAIN_PASSWORDS[users(:expired_user).user]
      }

    assert_select '#error_body', false
    assert_response :success
    assert !user.reload.enable?
  end

  test 'expired password' do
    user = User.find users(:administrator_user).id
    user.update_attribute :password_changed,
      get_test_parameter(:security_password_expire_time).to_i.next.days.ago

    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }
      
    assert_redirected_to change_password_user_url(user)
  end

  test 'warning about password expiration' do
    password_changed = get_test_parameter(
      :security_expire_notification).to_i.next.days.ago
    user = User.find users(:administrator_user).id

    user.update_attribute :password_changed, password_changed

    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }
    assert_redirected_to(:controller => :welcome, :action => :index)
    login_record = LoginRecord.find(:first, :conditions => {
        :user_id => users(:administrator_user).id,
        :organization_id => organizations(:default_organization).id
      })
    assert_kind_of LoginRecord, login_record
    assert_not_nil I18n.t(:'message.password_expire_in_x',
      :count => get_test_parameter(:security_expire_notification).to_i - 2),
      flash[:notice]
  end

  test 'concurrent users' do
    parameter = Parameter.first(
      :conditions => {
        :organization_id => organizations(:default_organization).id,
        :name => 'security_allow_concurrent_sessions'
      }
    )

    assert parameter.update_attributes(:value => 0)

    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }
    
    assert_redirected_to :controller => :welcome, :action => :index

    post :login, {:user => {
      :user => users(:administrator_user).user,
      :password => PLAIN_PASSWORDS[users(:administrator_user).user]
    }}, {}

    assert_response :success
    assert_select '#error_body', false
    assert_template 'users/login'
    assert_select '#notice p', I18n.t(:'message.you_are_already_logged')
  end

  test 'redirected instead of relogin' do
    post :login,
      :user => {
        :user => users(:administrator_user).user,
        :password => PLAIN_PASSWORDS[users(:administrator_user).user]
      }

    assert_redirected_to :controller => :welcome, :action => :index

    get :login

    assert_redirected_to :controller => :welcome, :action => :index
  end

  test 'first login' do
    assert_difference 'LoginRecord.count' do
      post :login,
        :user => {
          :user => users(:first_time_user).user,
          :password => PLAIN_PASSWORDS[users(:first_time_user).user]
        }
    end

    assert_redirected_to change_password_user_url(users(:first_time_user))
    login_record = LoginRecord.first(
      :conditions => {
        :user_id => users(:first_time_user).id,
        :organization_id => organizations(:default_organization).id
      })
    assert_kind_of LoginRecord, login_record
  end

  test 'list users' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_select '#error_body', false
    assert_template 'users/index'
  end

  test 'list users with search' do
    perform_auth
    get :index, :search => {:query => 'manager', :columns => ['user', 'name']}
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size
    assert_select '#error_body', false
    assert_template 'users/index'
  end


  test 'edit user when search match only one result' do
    perform_auth
    get :index, :search => {:query => 'admin', :columns => ['user', 'name']}
    assert_redirected_to edit_user_path(users(:administrator_user))
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size
  end

  test 'show user' do
    perform_auth
    get :show, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/show'
  end

  test 'new user' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/new'
  end

  test 'create user' do
    perform_auth
    counts_array = ['User.count', 'OrganizationRole.count', 
      'ActionMailer::Base.deliveries.size']
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      post :create, {
        :user => {
          :user => 'new_user',
          :name => 'New Name',
          :last_name => 'New Last Name',
          :email => 'new_user@newemail.net',
          :language => I18n.available_locales.last.to_s,
          :resource_id => resources(:auditor_resource).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => true,
          :organization_roles_attributes => {
            :new_1 => {
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          }
        }
      }
    end

    assert_difference ['User.count', 'OrganizationRole.count'] do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, {
          :user => {
            :user => 'new_user_2',
            :name => 'New Name2',
            :last_name => 'New Last Name2',
            :email => 'new_user2@newemail.net',
            :language => I18n.available_locales.last.to_s,
            :resource_id => resources(:auditor_resource).id,
            :logged_in => false,
            :enable => true,
            :send_notification_email => false,
            :organization_roles_attributes => {
              :new_1 => {
                :organization_id => organizations(:default_organization).id,
                :role_id => roles(:admin_role).id
              }
            }
          }
        }
      end
    end
  end

  test 'edit user' do
    perform_auth
    get :edit, :id => users(:administrator_user).user
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#error_body', false
    assert_template 'users/edit'
  end

  test 'update user' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    counts_array = ['User.count', 'OrganizationRole.count',
      'ActionMailer::Base.deliveries.size']

    assert_no_difference counts_array do
      put :update, {
        :id => users(:administrator_user).user,
        :user => {
          :user => 'updated_name',
          :name => 'Updated Name',
          :last_name => 'Updated Last Name',
          :email => 'updated_user@updatedemail.net',
          :language => I18n.available_locales.first.to_s,
          :resource_id => resources(:auditor_resource).id,
          :logged_in => false,
          :enable => true,
          :send_notification_email => false,
          :organization_roles_attributes => {
            organization_roles(:admin_role_for_administrator_user_in_default_organization).id => {
              :id => organization_roles(:admin_role_for_administrator_user_in_default_organization).id,
              :organization_id => organizations(:default_organization).id,
              :role_id => roles(:admin_role).id
            }
          }
        }
      }
    end

    assert_redirected_to users_path
    assert_not_nil assigns(:user)
    assert_equal 'updated_name', assigns(:user).user
  end

  test 'send notification on updated user' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    assert_no_difference 'User.count', 'OrganizationRole.count' do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        put :update, {
          :id => users(:administrator_user).user,
          :user => {
            :user => 'updated_name_2',
            :name => 'Updated Name',
            :last_name => 'Updated Last Name',
            :email => 'updated_user@updatedemail.net',
            :language => I18n.available_locales.first.to_s,
            :resource_id => resources(:auditor_resource).id,
            :logged_in => false,
            :enable => true,
            :send_notification_email => true,
            :organization_roles_attributes => {
              organization_roles(:admin_role_for_administrator_user_in_default_organization).id => {
                :id => organization_roles(:admin_role_for_administrator_user_in_default_organization).id,
                :organization_id => organizations(:default_organization).id,
                :role_id => roles(:admin_role).id
              }
            }
          }
        }
      end
    end

    assert_redirected_to users_path
    assert_not_nil assigns(:user)
    assert_equal 'updated_name_2', assigns(:user).user
  end

  test 'disable user' do
    perform_auth
    user = User.find(users(:supervisor_second_user).id)

    assert user.enable?
    assert user.findings.all_for_reallocation.empty?

    assert_no_difference 'User.count' do
      delete :destroy, :id => user.user
    end

    assert !user.reload.enable?
    assert_equal I18n.t(:'user.correctly_disabled'), flash[:notice]
    assert_redirected_to users_path
  end

  test 'disable audited user' do
    perform_auth
    assert_no_difference 'User.count' do
      delete :destroy, :id => users(:audited_user).user
    end

    assert_equal I18n.t(:'user.will_be_orphan_findings'), flash[:notice]
    assert_redirected_to users_path
  end

  test 'blank user password' do
    perform_auth
    counts_array = ['OldPassword.count', 'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    assert_difference counts_array do
      put :blank_password, :id => users(:administrator_user).user
    end
    
    assert_redirected_to users_path
    user = User.find(users(:administrator_user).id)
    assert_nil user.password
  end

  test 'change password' do
    perform_auth
    get :change_password, {:user => nil}
    assert_response :success
    assert_not_nil assigns(:auth_user)
    assert_select '#error_body', false
    assert_template 'users/change_password'

    assert_difference 'OldPassword.count' do
      put :change_password, {
        :user => {
          :password => 'new_password_123',
          :password_confirmation => 'new_password_123'
        }
      }

      user = User.find(users(:administrator_user).id)
      assert_redirected_to :controller => :users, :action => :login
      assert_equal User.digest('new_password_123', user.salt), user.password
    end
  end

  test 'change blank password' do
    get :change_password, {:user => nil,
      :confirmation_hash => users(:blank_password_user).change_password_hash}
    assert_response :success
    assert_select '#error_body', false
    assert_template 'users/change_password'

    put :change_password, {
      :user => {
        :password => 'new_password_123',
        :password_confirmation => 'new_password_123'
      },
      :confirmation_hash => users(:blank_password_user).change_password_hash
    }

    user = User.find(users(:blank_password_user).id)
    assert_redirected_to :controller => :users, :action => :login
    assert_equal User.digest('new_password_123', user.salt), user.password
    assert_not_nil user.last_access

    # No se puede usar 2 veces el mismo hash
    get :change_password, {:user => nil,
      :confirmation_hash => users(:blank_password_user).change_password_hash}
    assert_redirected_to :controller => :users, :action => :login
  end

  test 'change expired blank password' do
    put :change_password, {
      :user => {
        :password => 'new_password_123',
        :password_confirmation => 'new_password_123'
      },
      :confirmation_hash =>
        users(:expired_blank_password_user).change_password_hash
    }


    user = User.find(users(:expired_blank_password_user).id)
    assert_redirected_to :controller => :users, :action => :login
    assert_not_equal User.digest('new_password_123', user.salt), user.password
  end

  test 'change personal data' do
    assert_no_difference 'User.count' do
      perform_auth
      put :change_personal_data, {
        :user => {
          :name => 'Updated Name',
          :last_name => 'Updated Last Name',
          :language => 'es',
          :email => 'updated@email.com'
        }
      }
    end
    
    assert_response :success
    assert_not_nil assigns(:auth_user)
    assert_equal 'Updated Name', assigns(:auth_user).name
    assert_select '#error_body', false
    assert_template 'users/change_personal_data'
  end

  test 'logout' do
    perform_auth
    get :logout, :id => users(:administrator_user).user
    assert_nil session[:user_id]
    assert_redirected_to :controller => :users, :action => :login
  end

  test 'user findings reassignment' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :user_reassignment, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_reassignment'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        post :user_reassignment, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:audited_second_user).id,
            :with_findings => '1'
          }
        }
      end
    end

    assert_redirected_to users_path
    assert_equal I18n.t(:'user.user_reassignment_completed'), flash[:notice]
  end

  test 'user reviews reassignment' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :user_reassignment, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_reassignment'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        post :user_reassignment, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:audited_second_user).id,
            :with_reviews => '1'
          }
        }
      end
    end

    assert_redirected_to users_path
    assert_equal I18n.t(:'user.user_reassignment_completed'), flash[:notice]
  end

  test 'user reassignment of nothing' do
    perform_auth users(:administrator_second_user),
      organizations(:second_organization)
    get :user_reassignment, :id => users(:audited_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_reassignment'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'Notification.count' do
        post :user_reassignment, {
          :id => users(:audited_user).user,
          :user => {
            :id => users(:administrator_second_user).id
          }
        }
      end
    end

    assert_redirected_to users_path
    assert_equal I18n.t(:'user.user_reassignment_completed'), flash[:notice]
  end

  test 'user findings release' do
    perform_auth
    get :user_release, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_release'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      post :user_release, {
        :id => users(:auditor_user).user,
        :user => { :with_findings => '1' }
      }
    end

    assert_redirected_to users_path
    assert_equal I18n.t(:'user.user_release_completed'), flash[:notice]
  end

  test 'user reviews release' do
    perform_auth
    get :user_release, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_release'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      post :user_release, {
        :id => users(:auditor_user).user,
        :user => { :with_reviews => '1' }
      }
    end

    assert_redirected_to users_path
    assert_equal I18n.t(:'user.user_release_completed'), flash[:notice]
  end

  test 'user release of nothing' do
    perform_auth
    get :user_release, :id => users(:auditor_user).user

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
    assert_select '#error_body', false
    assert_template 'users/user_release'

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :user_release, {
        :id => users(:auditor_user).user
      }
    end

    assert_response :success
  end

  test 'export to pdf' do
    perform_auth

    assert_nothing_raised(Exception) { get :export_to_pdf }

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'user.pdf.pdf_name'), User.table_name)
  end

  test 'export with search' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :search => {
        :query => 'manager',
        :columns => ['user', 'name']
      }
    end

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'user.pdf.pdf_name'), User.table_name)
  end

  test 'get roles' do
    perform_auth
    xhr :get, :roles, {:id => organizations(:default_organization).id,
      :format => 'json'}
    assert_response :success
    roles = ActiveSupport::JSON.decode(@response.body)
    assert !roles.empty?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'admin' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Administrator
    assert_select '#error_body', false
    assert_template 'users/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'blank' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size # Blank and Expired blank
    assert_select '#error_body', false
    assert_template 'users/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'xyz' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # None
    assert_select '#error_body', false
    assert_template 'users/auto_complete_for_user'
  end
end