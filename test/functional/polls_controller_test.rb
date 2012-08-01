require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  test 'public and private actions' do
    id_param = {:id => polls(:poll_one).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:put, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list polls' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:polls)
    assert_select '#error_body', false
    assert_template 'polls/index'
  end

  test 'show poll' do
    perform_auth
    get :show, :id => polls(:poll_one).id
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/show'
  end

  test 'new poll' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/new'
  end

  test "create poll" do
    perform_auth
    assert_difference 'Poll.count', ActionMailer::Base.deliveries.count do
      assert_difference 'Answer.count', 2 do
        post :create, {
          :poll => {
            :user_id => users(:poll_user).id,
            :questionnaire_id => questionnaires(:questionnaire_one).id,
            :organization_id => organizations(:default_organization).id
          }
        }
      end
    end
    assert_redirected_to poll_path(assigns(:poll))
  end

  test 'edit poll' do
    perform_auth users(:poll_user)
    get :edit, :id => polls(:poll_one).id
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/edit'
  end

  test "update poll" do
    perform_auth users(:poll_user)
    assert_no_difference ['Poll.count'] do
      put :update, {
        :id => polls(:poll_one).id,
        :poll => {
          :comments => 'Encuesta actualizada'
        }
      }
    end
    assert_redirected_to welcome_url
    assert_not_nil assigns(:poll)
    assert_equal 'Encuesta actualizada', assigns(:poll).comments
    assert_equal true, assigns(:poll).answered
  end

  test 'destroy poll' do
    perform_auth
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        delete :destroy, :id => polls(:poll_one).id
      end
    end

    assert_redirected_to polls_url
  end
end
