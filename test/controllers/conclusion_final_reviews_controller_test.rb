require 'test_helper'

# Pruebas para el controlador de informes finales
class ConclusionFinalReviewsControllerTest < ActionController::TestCase
  fixtures :conclusion_reviews

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  setup do
    @request.host = "#{organizations(:cirope).prefix}.localhost.i"
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      :params => {
        :id => conclusion_reviews(:conclusion_past_final_review).to_param
      }
    }
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:get, :export_to_pdf, id_param]
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

  test 'list conclusion_final_reviews' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_template 'conclusion_final_reviews/index'
  end

  test 'list conclusion_final_reviews with search' do
    login
    get :index, :params => {
      :search => {
        :query => '1',
        :columns => ['identification', 'project']
      }
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 2, assigns(:conclusion_final_reviews).count
    assert_template 'conclusion_final_reviews/index'
  end

  test 'list conclusion_final_reviews with search by date and sort' do
    login
    get :index, :params => {
      :search => {
        :query => "> #{I18n.l(3.months.ago.to_date, :format => :minimal)}",
        :columns => ['issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 2, assigns(:conclusion_final_reviews).count
    assert assigns(:conclusion_final_reviews).all? {|cfr| cfr.issue_date > 3.months.ago.to_date}
    assert_template 'conclusion_final_reviews/index'
  end

  test 'show conclusion_final_review' do
    login
    get :show, :params => {
      :id => conclusion_reviews(:conclusion_past_final_review).id
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_template 'conclusion_final_reviews/show'
  end

  test 'new conclusion final review' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_template 'conclusion_final_reviews/new'
  end

  test 'new json conclusion final review' do
    login
    get :new, :params => { :format => 'json' }, xhr: true
    assert_response :success
    assert_nothing_raised do
      ActiveSupport::JSON.decode(@response.body)
    end
  end

  test 'new for existent conclusion final review' do
    login
    get :new, :params => {
      :review => conclusion_reviews(:conclusion_past_final_review).review_id
    }

    assert_redirected_to edit_conclusion_final_review_url(
      conclusion_reviews(:conclusion_past_final_review))
  end

  test 'create conclusion final review' do
    login
    assert_difference 'ConclusionFinalReview.count' do
      post :create, :params => {
        :conclusion_final_review => {
          :review_id => reviews(:review_approved_with_conclusion).id,
          :issue_date => Date.today,
          :close_date => Date.tomorrow,
          :applied_procedures => 'New applied procedures',
          :conclusion => 'New conclusion',
          :summary => 'ACT 12',
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => 'Do the evolution',
          :evolution_justification => 'Ok',
          :observations => nil
        }
      }
    end
  end

  test 'edit conclusion final review' do
    login
    get :edit, :params => {
      :id => conclusion_reviews(:conclusion_past_final_review).id
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_template 'conclusion_final_reviews/edit'
  end

  test 'update conclusion final review' do
    assert_no_difference 'ConclusionFinalReview.count' do
      login
      patch :update, :params => {
        :id => conclusion_reviews(:conclusion_past_final_review).id,
        :conclusion_final_review => {
          :review_id => reviews(:review_with_conclusion).id,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'Updated applied procedures',
          :conclusion => 'Updated conclusion',
          :summary => 'ACT Updated',
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => 'Do the evolution',
          :evolution_justification => 'Ok',
          :observations => nil
        }
      }
    end

    assert_redirected_to conclusion_final_reviews_url
    assert_equal 'ACT Updated', conclusion_reviews(:conclusion_past_final_review).reload.summary
  end

  test 'export conclusion final review' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'export conclusion draft review without control objectives excluded from score' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => {
        :id => conclusion_review.id,
        :export_options => { :hide_control_objectives_excluded_from_score => '1' }
      }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'export conclusion draft review brief' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => {
        :id => conclusion_review.id,
        :export_options => { :brief => '1' }
      }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'score sheet of final review' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      get :score_sheet, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.review.relative_score_sheet_path

    assert_nothing_raised do
      get :score_sheet, :params => { :id => conclusion_review.id, :global => 1 }
    end

    assert_redirected_to(
      conclusion_review.review.relative_global_score_sheet_path)
  end

  test 'download work papers' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      get :download_work_papers, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.review.relative_work_papers_zip_path
  end

  test 'download bundle' do
    login

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised do
      post :create_bundle, :params => {
        :id => conclusion_review.id,
        :index_items => "one\ntwo"
      }
    end

    assert_redirected_to conclusion_review.relative_bundle_zip_path
    FileUtils.rm conclusion_review.absolute_bundle_zip_path
  end

  test 'compose email' do
    login
    get :compose_email, :params => {
      :id => conclusion_reviews(:conclusion_past_final_review).id
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_template 'conclusion_final_reviews/compose_email'
  end

  test 'send by email' do
    login

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, :params => {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          },
          # Con duplicados igual envía solo un correo
          users(:administrator).id + 1 => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    assert_redirected_to :action => :edit, :id => conclusion_reviews(
      :conclusion_current_final_review).id

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      patch :send_by_email, :params => {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          },
          # Sin confirmación
          users(:audited).id => {
            :id => users(:audited).id,
            :data => users(:audited).name
          }
        }
      }
    end

    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    assert_redirected_to :action => :edit, :id => conclusion_reviews(
      :conclusion_current_final_review).id
  end

  test 'send by email with multiple attachments' do
    login

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, :params => {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :email_note => 'note in *textile* _format_'
        },
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    assert_equal 2, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /textile/, text_part

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, :params => {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :include_global_score_sheet => '1',
          :email_note => 'note in *textile* _format_'
        },
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    assert_equal 3, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /textile/, text_part
  end

  test 'export list to pdf' do
    login

    assert_nothing_raised { get :export_list_to_pdf }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_final_review.pdf.pdf_name'),
      ConclusionFinalReview.table_name)
  end

  test 'export list with search' do
    login

    assert_nothing_raised do
      get :export_list_to_pdf, :params => {
        :search => {
          :query => '1',
          :columns => ['period', 'identification']
        }
      }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_final_review.pdf.pdf_name'),
      ConclusionFinalReview.table_name)
  end
end
