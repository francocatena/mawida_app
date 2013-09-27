require 'test_helper'

# Pruebas para el controlador de reportes de comité
class FollowUpCommitteeControllerTest < ActionController::TestCase
  fixtures :findings

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :synthesis_report, :weaknesses_by_risk_report,
      :fixed_weaknesses_report, :rescheduled_being_implemented_weaknesses_report,
      :control_objective_stats, :process_control_stats, :create_synthesis_report,
      :create_weaknesses_by_risk_report, :create_fixed_weaknesses_report,
      :create_rescheduled_being_implemented_weaknesses_report,
      :create_control_objective_stats, :create_process_control_stats]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
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
    assert_template 'follow_up_committee/index'
  end

  test 'synthesis report' do
    perform_auth

    get :synthesis_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/synthesis_report'

    assert_nothing_raised(Exception) do
      get :synthesis_report, :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/synthesis_report'
  end

  test 'filtered synthesis report' do
    perform_auth
    get :synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'three'
      }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).size
    assert_template 'follow_up_committee/synthesis_report'
  end

  test 'create synthesis report' do
    perform_auth

    post :create_synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'qa indicators' do
    perform_auth

    get :qa_indicators
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/qa_indicators'

    assert_nothing_raised(Exception) do
      get :qa_indicators, :qa_indicators => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/qa_indicators'
  end

  test 'create qa indicators' do
    perform_auth

    post :create_qa_indicators, :qa_indicators => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.qa_indicators.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'qa_indicators', 0)
  end

  test 'weaknesses by risk report' do
    perform_auth

    get :weaknesses_by_risk_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/weaknesses_by_risk_report'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_risk_report, :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/weaknesses_by_risk_report'
  end

  test 'filtered weaknesses by risk report' do
    perform_auth

    get :weaknesses_by_risk_report, :weaknesses_by_risk_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'three'
    }

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/weaknesses_by_risk_report'
  end

  test 'create weaknesses by risk report' do
    perform_auth

    get :create_weaknesses_by_risk_report, :weaknesses_by_risk_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_report', 0)
  end

  test 'fixed weaknesses report' do
    perform_auth

    get :fixed_weaknesses_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/fixed_weaknesses_report'

    assert_nothing_raised(Exception) do
      get :fixed_weaknesses_report, :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/fixed_weaknesses_report'
  end

  test 'filtered fixed weaknesses report' do
    perform_auth

    get :fixed_weaknesses_report, :fixed_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'three'
    }

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/fixed_weaknesses_report'
  end

  test 'create fixed weaknesses report' do
    perform_auth

    get :create_fixed_weaknesses_report, :fixed_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'fixed_weaknesses_report', 0)
  end

  test 'rescheduled being implemented weaknesses report' do
    perform_auth

    get :rescheduled_being_implemented_weaknesses_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/rescheduled_being_implemented_weaknesses_report'

    assert_nothing_raised(Exception) do
      get :rescheduled_being_implemented_weaknesses_report,
        :rescheduled_being_implemented_weaknesses_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
          }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/rescheduled_being_implemented_weaknesses_report'
  end

  test 'filtered rescheduled weaknesses report' do
    perform_auth

    get :rescheduled_being_implemented_weaknesses_report,
      :rescheduled_being_implemented_weaknesses_report => {
        :from_date => 2.years.ago.to_date,
        :to_date => 2.years.from_now.to_date,
        :rescheduling => 2,
        :detailed => 1
      }

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/rescheduled_being_implemented_weaknesses_report'
  end

  test 'create rescheduled weaknesses report' do
    perform_auth

    get :create_rescheduled_being_implemented_weaknesses_report,
    :rescheduled_being_implemented_weaknesses_report => {
      :from_date => 2.years.ago.to_date,
      :to_date => 2.years.from_now.to_date,
      :rescheduling => 1,
      :detailed => 1
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.rescheduled_being_implemented_weaknesses_report.pdf_name',
        :from_date => 2.years.ago.to_date.to_formatted_s(:db),
        :to_date => 2.years.from_now.to_date.to_formatted_s(:db)),
      'rescheduled_being_implemented_weaknesses_report', 0)
  end

  test 'control objective stats report' do
    perform_auth

    get :control_objective_stats
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/control_objective_stats'

    assert_nothing_raised(Exception) do
      get :control_objective_stats, :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/control_objective_stats'
  end

  test 'filtered control objective stats report' do
    perform_auth

    get :control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :control_objective => 'a'
    }

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/control_objective_stats'
  end

  test 'create control objective stats report' do
    perform_auth

    get :create_control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats', 0)
  end

  test 'process control stats report' do
    perform_auth

    get :process_control_stats
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/process_control_stats'

    assert_nothing_raised(Exception) do
      get :process_control_stats, :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/process_control_stats'
  end

  test 'filtered process control stats report' do
    perform_auth

    get :process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
    }

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_committee/process_control_stats'
  end

  test 'create process control stats report' do
    perform_auth

    get :create_process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end
end
