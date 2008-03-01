require 'test_helper'

# Pruebas para el controlador de reportes de ejecución
class ExecutionReportsControllerTest < ActionController::TestCase
  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :weaknesses_by_state]
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

  test 'list reports' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_select '#error_body', false
    assert_template 'execution_reports/index'
  end

  test 'detailed management report' do
    perform_auth

    get :detailed_management_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'execution_reports/detailed_management_report'

    assert_nothing_raised(Exception) do
      post :detailed_management_report, :detailed_management_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'execution_reports/detailed_management_report'
  end

  test 'download detailed management report' do
    perform_auth

    get :detailed_management_report, :download => 1, :detailed_management_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      }

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'execution_reports.detailed_management_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)
  end

  test 'weaknesses by state report' do
    perform_auth

    get :weaknesses_by_state
    assert_response :success
    assert_select '#error_body', false
    assert_template 'execution_reports/weaknesses_by_state'

    assert_nothing_raised(Exception) do
      post :weaknesses_by_state, :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'execution_reports/weaknesses_by_state'
  end

  test 'download weaknesses by state report' do
    perform_auth
    get :weaknesses_by_state, :download => 1, :weaknesses_by_state => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
    }

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'execution_reports.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)
  end
end