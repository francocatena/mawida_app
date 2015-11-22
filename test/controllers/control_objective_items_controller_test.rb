require 'test_helper'

# Pruebas para el controlador de items de objetivos de control
class ControlObjectiveItemsControllerTest < ActionController::TestCase
  fixtures :control_objective_items, :control_objectives, :reviews

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => control_objective_items(:bcra_A4609_security_management_responsible_dependency_item).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :edit, id_param],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list control objective items' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert_template 'control_objective_items/index'
  end

  test 'list control objective items with search' do
    login
    get :index, :search => {
      :query => 'seguridad',
      :columns => ['control_objective_text', 'review']
    }
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert assigns(:control_objectives).count > 0
    assert(assigns(:control_objectives).all? do |coi|
      coi.control_objective_text.match(/seguridad/i)
    end)
    assert_template 'control_objective_items/index'
  end

  test 'edit control objective item when search match only one result' do
    login
    get :index, :search => {
      :query => 'dependencia y responsable',
      :columns => ['control_objective_text', 'review']
    }

    assert_redirected_to control_objective_item_url(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item))
    assert_not_nil assigns(:control_objectives)
    assert_equal 1, assigns(:control_objectives).count
  end

  test 'show control_objective_item' do
    login
    get :show, :id => control_objective_items(:bcra_A4609_security_management_responsible_dependency_item).id
    assert_response :success
    assert_not_nil assigns(:control_objective_item)
    assert_template 'control_objective_items/show'
  end

  test 'edit control_objective_item' do
    login
    get :edit, :id => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:control_objective_item)
    assert_template 'control_objective_items/edit'
  end

  test 'edit continuous control objective item' do
    login
    get :edit, :id => control_objective_items(
      :iso_27000_security_organization_4_4_continuous_item).id
    assert_response :success
    assert_not_nil assigns(:control_objective_item)
    assert_template 'control_objective_items/_business_unit_score'
  end

  test 'update control_objective_item' do
    assert_no_difference ['ControlObjectiveItem.count', 'Control.count'] do
      assert_difference 'WorkPaper.count', 2 do
        login
        patch :update, {
          :id => control_objective_items(
            :bcra_A4609_security_management_responsible_dependency_item_editable).id,
          :control_objective_item => {
            :control_objective_text => 'Updated text',
            :relevance => ControlObjectiveItem.relevances_values.last,
            :control_attributes => {
              :id => controls(:bcra_A4609_security_management_responsible_dependency_item_editable_control_1).id,
              :control => 'Updated control',
              :effects => 'Updated effects',
              :design_tests => 'Updated design tests',
              :compliance_tests => 'Updated compliance tests',
              :sustantive_tests => 'Updated sustantive tests'
            },
            :design_score => ControlObjectiveItem.qualifications_values.last,
            :compliance_score => ControlObjectiveItem.qualifications_values.last,
            :audit_date => 10.days.from_now.to_date,
            :auditor_comment => 'Updated comment',
            :control_objective_id =>
              control_objectives(:iso_27000_security_organization_4_1).id,
            :review_id => reviews(:review_with_conclusion).id,
            :work_papers_attributes => [
              {
                :name => 'New workpaper name',
                :code => 'PTOC 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:cirope).id,
                :file_model_attributes =>
                  { :file => fixture_file_upload(TEST_FILE, 'text/plain') }
              },
              {
                :name => 'New workpaper2 name',
                :code => 'PTOC 21',
                :number_of_pages => '10',
                :description => 'New workpaper2 description',
                :organization_id => organizations(:cirope).id,
                :file_model_attributes =>
                  { :file => fixture_file_upload(TEST_FILE, 'text/plain') }
              }
            ]
          }
        }
      end
    end

    assert_redirected_to edit_control_objective_item_url(
      control_objective_items(
        :bcra_A4609_security_management_responsible_dependency_item_editable))
    assert_not_nil assigns(:control_objective_item)
    assert_equal 'Updated text',
      assigns(:control_objective_item).control_objective_text
  end

  test 'update continuous control_objective_item' do
    assert_no_difference ['ControlObjectiveItem.count', 'Control.count'] do
      # One explicit and two via business unit type
      assert_difference 'BusinessUnitScore.count', 3 do
        login

        patch :update, {
          :id => control_objective_items(:iso_27000_security_organization_4_4_continuous_item).id,
          :control_objective_item => {
            :control_objective_text => 'Updated text',
            :relevance => ControlObjectiveItem.relevances_values.last,
            :control_attributes => {
              :id => controls(:iso_27000_security_organization_4_4_item_control_1).id,
              :control => 'Updated control',
              :effects => 'Updated effects',
              :design_tests => 'Updated design tests',
              :compliance_tests => 'Updated compliance tests',
              :sustantive_tests => 'Updated sustantive tests'
            },
            :design_score => ControlObjectiveItem.qualifications_values.last,
            :compliance_score => ControlObjectiveItem.qualifications_values.last,
            :audit_date => 10.days.from_now.to_date,
            :auditor_comment => 'Updated comment',
            :control_objective_id => control_objectives(:iso_27000_security_organization_4_4_continuous).id,
            :review_id => reviews(:review_without_conclusion).id,
            :business_unit_scores_attributes => [
              {
                :business_unit_id => business_units(:business_unit_two).id,
                :design_score => ControlObjectiveItem.qualifications_values.last,
                :compliance_score => ControlObjectiveItem.qualifications_values.last,
                :sustantive_score => ControlObjectiveItem.qualifications_values.last
              }
            ],
            :business_unit_type_ids => [business_unit_types(:consolidated_substantive).id.to_s]
          }
	      }
      end
    end

    assert_redirected_to edit_control_objective_item_url(
      control_objective_items( :iso_27000_security_organization_4_4_continuous_item))
    assert_not_nil assigns(:control_objective_item)
    assert_equal 'Updated text',
      assigns(:control_objective_item).control_objective_text
  end

  test 'destroy control_objective_item' do
    login
    assert_difference 'ControlObjectiveItem.count', -1 do
      delete :destroy, :id => control_objective_items(
        :iso_27000_security_organization_4_3_item_editable_without_findings).id
    end

    assert_redirected_to control_objective_items_url
  end

  test 'auto complete for business unit' do
    login
    get :auto_complete_for_business_unit, {
      :q => 'fifth', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_units.size # Fifth is in another organization

    get :auto_complete_for_business_unit, {
      :q => 'one', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_units.size # One only
    assert business_units.all? { |u| (u['label'] + u['informal']).match /one/i }

    get :auto_complete_for_business_unit, {
      :q => 'business', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 4, business_units.size # All in the organization (one, two, three and four)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }
  end

  test 'auto complete for business unit type' do
    login
    get :auto_complete_for_business_unit_type, {
      :q => 'noway', :format => :json
    }
    assert_response :success

    business_unit_types = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_unit_types.size # Fifth is in another organization

    get :auto_complete_for_business_unit_type, {
      :q => 'cycle', :format => :json
    }
    assert_response :success

    business_unit_types = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_unit_types.size # One only
    assert business_unit_types.all? { |u| u['label'].match /cycle/i }
  end
end
