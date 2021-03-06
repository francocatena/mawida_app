require 'test_helper'

class ResourceClassesControllerTest < ActionController::TestCase
  setup do
    @resource_class = resource_classes :hardware_resources

    login
  end

  test 'list resource classes' do
    get :index
    assert_response :success
    assert_not_nil assigns(:resource_classes)
    assert_template 'resource_classes/index'
  end

  test 'show resource class' do
    get :show, params: { id: @resource_class }
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_template 'resource_classes/show'
  end

  test 'new resource class' do
    get :new
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_template 'resource_classes/new'
  end

  test 'create resource class' do
    assert_difference ['ResourceClass.count', 'Resource.count'] do
      post :create, params: {
        resource_class: {
          name: 'New resource class',
          resources_attributes: [
            {
              name: 'New name',
              description: 'New description'
            }
          ]
        }
      }
    end
  end

  test 'edit resource class' do
    get :edit, params: { id: @resource_class }
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_template 'resource_classes/edit'
  end

  test 'update resource class' do
    assert_no_difference 'ResourceClass.count' do
      assert_difference 'Resource.count' do
        patch :update, params: {
          id: @resource_class,
          resource_class: {
            name: 'Updated resource class',
            resources_attributes: [
              {
                id: resources(:laptop_resource).id,
                name: 'Updated name',
                description: 'Updated description'
              }, {
                name: 'New name from update',
                description: 'New description from update'
              }
            ]
          }
        }
      end
    end

    assert_redirected_to resource_classes_url
    assert_not_nil assigns(:resource_class)
    assert_equal 'Updated resource class', assigns(:resource_class).name
  end

  test 'destroy resource class' do
    assert_difference 'ResourceClass.count', -1 do
      delete :destroy, params: { id: @resource_class }
    end

    assert_redirected_to resource_classes_url
  end
end
