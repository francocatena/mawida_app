require 'test_helper'

# Pruebas para el controlador de reportes de auditoría
class FollowUpAuditControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :synthesis_report, :qa_indicators, :weaknesses_by_state,
      :weaknesses_by_risk, :weaknesses_by_audit_type,
      :weaknesses_by_risk_report, :fixed_weaknesses_report,
      :weaknesses_by_month
    ]

    private_actions.each do |action|
      get action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list reports' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'follow_up_audit/index'
  end

  test 'synthesis report' do
    login

    get :synthesis_report, :params => { :controller_name => 'follow_up' }
    assert_response :success
    assert_template 'follow_up_audit/synthesis_report'

    assert_nothing_raised do
      get :synthesis_report, :params => {
        :synthesis_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up'
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/synthesis_report'
  end

  test 'filtered synthesis report' do
    login
    get :synthesis_report, :params => {
      :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three'
      },
      :controller_name => 'follow_up'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_template 'follow_up_audit/synthesis_report'
  end

  test 'create synthesis report' do
    login

    post :create_synthesis_report, :params => {
      :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'review stats report' do
    login

    get :review_stats_report, :params => { :controller_name => 'follow_up' }
    assert_response :success
    assert_template 'follow_up_audit/review_stats_report'

    assert_nothing_raised do
      get :review_stats_report, :params => {
        :review_stats_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up'
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/review_stats_report'
  end

  test 'filtered review stats report' do
    login
    get :review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three'
      },
      :controller_name => 'follow_up'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_template 'follow_up_audit/review_stats_report'
  end

  test 'create review stats report' do
    login

    post :create_review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.review_stats_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'review_stats_report', 0)
  end

  test 'qa indicators' do
    login

    get :qa_indicators
    assert_response :success
    assert_template 'follow_up_audit/qa_indicators'

    assert_nothing_raised do
      get :qa_indicators, :params => {
        :qa_indicators => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/qa_indicators'
  end

  test 'create qa indicators' do
    login

    post :create_qa_indicators, :params => {
      :qa_indicators => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.qa_indicators.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'qa_indicators', 0)
  end

  test 'weaknesses by state report' do
    login

    get :weaknesses_by_state
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_state'

    assert_nothing_raised do
      get :weaknesses_by_state, :params => {
        :weaknesses_by_state => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    login
    post :create_weaknesses_by_state, :params => {
      :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_state', 0)
  end

  test 'weaknesses by risk' do
    login

    get :weaknesses_by_risk
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk'

    assert_nothing_raised do
      get :weaknesses_by_risk, :params => {
        :weaknesses_by_risk => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk'
  end

  test 'create weaknesses by risk' do
    login

    post :create_weaknesses_by_risk, :params => {
      :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk', 0)
  end

  test 'weaknesses by audit type report' do
    login

    get :weaknesses_by_audit_type
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_audit_type'

    assert_nothing_raised do
      get :weaknesses_by_audit_type, :params => {
        :weaknesses_by_audit_type => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    login

    post :create_weaknesses_by_audit_type, :params => {
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end

  test 'units analysis report' do
    login

    get :follow_up_cost_analysis
    assert_response :success
    assert_template 'follow_up_audit/follow_up_cost_analysis'

    assert_nothing_raised do
      get :follow_up_cost_analysis, :params => {
        :follow_up_cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/follow_up_cost_analysis'
  end

  test 'create units analysis report' do
    login

    post :create_follow_up_cost_analysis, :params => {
      :follow_up_cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.follow_up_cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'follow_up_cost_analysis', 0)
  end

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'

    assert_nothing_raised do
      get :weaknesses_by_risk_report, :params => {
        :weaknesses_by_risk_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'
  end

  test 'filtered weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report, :params => {
      :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'
  end

  test 'create weaknesses by risk report' do
    login

    get :create_weaknesses_by_risk_report, :params => {
      :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_report', 0)
  end

  test 'weaknesses by month' do
    login

    get :weaknesses_by_month
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'

    assert_nothing_raised do
      get :weaknesses_by_month, :params => {
        :weaknesses_by_month => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'
  end

  test 'filtered weaknesses by month' do
    login

    get :weaknesses_by_month, :params => {
      :weaknesses_by_month => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'
  end

  test 'create weaknesses by month' do
    login

    get :create_weaknesses_by_month, :params => {
      :weaknesses_by_month => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_month.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_month', 0)
  end

  test 'fixed weaknesses report' do
    login

    get :fixed_weaknesses_report
    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'

    assert_nothing_raised do
      get :fixed_weaknesses_report, :params => {
        :fixed_weaknesses_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'
  end

  test 'filtered fixed weaknesses report' do
    login

    get :fixed_weaknesses_report, :params => {
      :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'
  end

  test 'create fixed weaknesses report' do
    login

    get :create_fixed_weaknesses_report, :params => {
      :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'fixed_weaknesses_report', 0)
  end

  test 'control objective stats report' do
    login

    get :control_objective_stats
    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'

    assert_nothing_raised do
      get :control_objective_stats, :params => {
        :control_objective_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'
  end

  test 'filtered control objective stats report' do
    login

    get :control_objective_stats, :params => {
      :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :params => {
      :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats', 0)
  end

  test 'control objective stats by review report' do
    login

    get :control_objective_stats_by_review
    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'

    assert_nothing_raised do
      get :control_objective_stats_by_review, :params => {
        :control_objective_stats_by_review => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => true
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'
  end

  test 'filtered control objective stats by review report' do
    login

    get :control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
      },
      :controller_name => 'follow_up',
      :final => true
    }

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'
  end

  test 'create control objective stats by review report' do
    login

    get :create_control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => true
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.control_objective_stats_by_review.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats_by_review', 0)
  end

  test 'process control stats report' do
    login

    get :process_control_stats
    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'

    assert_nothing_raised do
      get :process_control_stats, :params => {
        :process_control_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'
  end

  test 'filtered process control stats report' do
    login

    get :process_control_stats, :params => {
      :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :best_practice => 'a',
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :process_control => 'seg',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'
  end

  test 'create process control stats report' do
    login

    get :create_process_control_stats, :params => {
      :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end

  test 'weaknesses graphs for user' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :user_id => users(:administrator).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses graphs for business unit' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :business_unit_id => business_units(:business_unit_one).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses graphs for process control' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :process_control_id => process_controls(:security_policy).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses report' do
    login

    get :weaknesses_report
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'

    assert_nothing_raised do
      get :weaknesses_report, :params => {
        :weaknesses_report => {
          :review                    => '1',
          :project                   => '2',
          :process_control           => '3',
          :control_objective         => '4',
          :tags                      => '5',
          :user_id                   => users(:administrator).id.to_s,
          :finding_status            => '1',
          :finding_title             => '1',
          :risk                      => '1',
          :priority                  => Finding.priorities_values.first,
          :issue_date                => Date.today.to_s(:db),
          :issue_date_operator       => '=',
          :origination_date          => Date.today.to_s(:db),
          :origination_date_operator => '>',
          :follow_up_date            => Date.today.to_s(:db),
          :follow_up_date_until      => Date.today.to_s(:db),
          :follow_up_date_operator   => 'between',
          :solution_date             => Date.today.to_s(:db),
          :solution_date_operator    => '='
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'
  end

  test 'filtered weaknesses report' do
    login

    get :weaknesses_report, :params => {
      :weaknesses_report => {
        :finding_status => Finding::STATUS[:being_implemented].to_s,
        :finding_title  => 'a'
      }
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'
  end

  test 'create weaknesses report' do
    login

    post :create_weaknesses_report, :params => {
      :weaknesses_report => {
        :finding_status => Finding::STATUS[:being_implemented].to_s
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'
    }

    assert_response :redirect
  end

  test 'benefits report' do
    login

    get :benefits
    assert_response :success
    assert_template 'follow_up_audit/benefits'

    assert_nothing_raised do
      get :benefits, :params => {
        :benefits => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/benefits'
  end

  test 'filtered benefits report' do
    login

    get :benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/benefits'
  end

  test 'create benefits report' do
    login

    get :create_benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.benefits.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'benefits', 0)
  end
end
