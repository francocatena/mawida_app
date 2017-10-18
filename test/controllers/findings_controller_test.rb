require 'test_helper'

class FindingsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    login
  end

  test 'list findings' do
    get :index, params: { completed: 'incomplete' }

    assert_response :success
  end

  test 'list findings for follow_up_committee' do
    login user: users(:committee)

    get :index, params: { completed: 'incomplete' }

    assert_response :success
  end

  test 'list findings with search and sort' do
    get :index, params: {
      completed: 'incomplete',
      search: {
        query:   '1 2 4 y w',
        columns: ['title', 'review'],
        order:   'review'
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.review.identification.match /1 2 4/i }
  end

  test 'list findings sorted with search by date' do
    get :index, params: {
      completed: 'incomplete',
      search: {
        query:   "> #{I18n.l(4.days.ago.to_date, format: :minimal)}",
        columns: ['review', 'issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 4, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date }
  end

  test 'list findings for user' do
    user = users :first_time

    get :index, params: {
      completed: 'incomplete',
      user_id:   user.id
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for responsible auditor' do
    user = users :first_time

    get :index, params: {
      completed:      'incomplete',
      user_id:        user.id,
      as_responsible: true
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for process owner' do
    user = users :audited

    login user: user

    get :index, params: {
      completed: 'incomplete',
      as_owner:  true
    }

    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| f.finding_user_assignments.owners.map(&:user).include?(user) }
  end

  test 'list findings for specific ids' do
    ids = [
      findings(:being_implemented_weakness).id,
      findings(:unconfirmed_for_notification_weakness).id
    ]

    get :index, params: {
      completed: 'incomplete',
      ids:       ids
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
  end

  test 'list findings as CSV' do
    get :index, params: {
      completed: 'incomplete',
      format:    :csv
    }

    assert_response :success
    assert_equal "#{Mime[:csv]}", @response.content_type
  end

  test 'list findings as PDF' do
    get :index, params: {
      completed: 'incomplete',
      format:    :pdf
    }

    assert_redirected_to /\/private\/.*\/findings\/.*\.pdf$/
    assert_equal "#{Mime[:pdf]}", @response.content_type
  end

  test 'list findings as corporate user' do
    organization = organizations :twitter

    login prefix: organization.prefix

    get :index, params: { completed: 'incomplete' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).any? { |f| f.organization_id != organization.id }
  end

  test 'show finding' do
    get :show, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'show finding for follow_up_committee' do
    login user: users(:committee)

    get :show, params: {
      completed: 'incomplete',
      id:        findings(:being_implemented_oportunity)
    }

    assert_response :success
  end

  test 'edit finding as auditor' do
    login user: users(:auditor)

    get :edit, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'edit finding as audited' do
    login user: users(:audited)

    get :edit, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'unauthorized edit finding' do
    login user: users(:audited_second)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'complete',
        id:        findings(:being_implemented_weakness_on_final)
      }
    end
  end

  test 'unauthorized edit of incomplete finding' do
    login user: users(:audited)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'incomplete',
        id:        findings(:incomplete_weakness)
      }
    end
  end

  test 'edit implemented audited finding' do
    finding = findings :being_implemented_weakness

    finding.update_column :state, Finding::STATUS[:implemented_audited]

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'complete',
        id:        finding
      }
    end
  end

  test 'update finding' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    difference_counts = [
      'WorkPaper.count',
      'FindingAnswer.count',
      'Cost.count',
      'FindingRelation.count',
      'BusinessUnitFinding.count',
      'Tagging.count'
    ]

    assert_enqueued_emails 1 do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          patch :update, params: {
            completed: 'incomplete',
            id: finding,
            finding: {
              control_objective_item_id:
                control_objective_items(:impact_analysis_item_editable).id,
              review_code: 'O020',
              title: 'Title',
              description: 'Updated description',
              answer: 'Updated answer',
              current_situation: 'Updated current situation',
              current_situation_verified: '1',
              audit_comments: 'Updated audit comments',
              state: Finding::STATUS[:unconfirmed],
              origination_date: 1.day.ago.to_date.to_s(:db),
              audit_recommendations: 'Updated proposed action',
              effect: 'Updated effect',
              risk: Finding.risks_values.first,
              priority: Finding.priorities_values.first,
              compliance: 'no',
              operational_risk: 'internal fraud',
              impact: ['econimic', 'regulatory'],
              internal_control_components: ['risk_evaluation', 'monitoring'],
              business_unit_ids: [business_units(:business_unit_three).id],
              finding_user_assignments_attributes: [
                {
                  id: finding_user_assignments(:unconfirmed_weakness_audited).id,
                  user_id: users(:audited).id,
                  process_owner: '1'
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
                  user_id: users(:auditor).id,
                  process_owner: '0'
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
                  user_id: users(:supervisor).id,
                  process_owner: '0'
                }
              ],
              work_papers_attributes: [
                {
                  name: 'New workpaper name',
                  code: 'PTSO 20',
                  file_model_attributes: {
                    file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                  }
                }
              ],
              finding_answers_attributes: [
                {
                  answer: 'New answer',
                  user_id: users(:supervisor).id,
                  notify_users: '1',
                  file_model_attributes: {
                    file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                  }
                }
              ],
              finding_relations_attributes: [
                {
                  description: 'Duplicated',
                  related_finding_id: findings(:unanswered_weakness).id
                }
              ],
              taggings_attributes: [
                {
                  tag_id: tags(:important).id
                }
              ],
              costs_attributes: [
                {
                  cost: '12.5',
                  cost_type: 'audit',
                  description: 'New cost description',
                  user_id: users(:administrator).id
                }
              ]
            }
          }
        end
      end
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_equal 'Updated description', finding.reload.description
  end

  test 'update finding with audited user' do
    finding = findings :unconfirmed_weakness

    no_difference_count = [
      'WorkPaper.count',
      'FindingRelation.count'
    ]

    difference_count = [
      'FindingAnswer.count',
      'Cost.count',
      'FileModel.count'
    ]

    login user: users(:audited)

    assert_no_difference no_difference_count do
      assert_difference difference_count do
        patch :update, params: {
          completed: 'incomplete',
          id: finding,
          finding: {
            control_objective_item_id: control_objective_items(:impact_analysis_item_editable).id,
            review_code: 'O020',
            title: 'Title',
            description: 'Updated description',
            answer: 'Updated answer',
            current_situation: 'Updated current situation',
            current_situation_verified: '1',
            audit_comments: 'Updated audit comments',
            state: Finding::STATUS[:unconfirmed],
            origination_date: 35.day.ago.to_date.to_s(:db),
            solution_date: 31.days.from_now.to_date,
            audit_recommendations: 'Updated proposed action',
            effect: 'Updated effect',
            risk: Finding.risks_values.first,
            priority: Finding.priorities_values.first,
            follow_up_date: 3.days.from_now.to_date,
            compliance: 'no',
            operational_risk: 'internal fraud',
            impact: ['econimic', 'regulatory'],
            internal_control_components: ['risk_evaluation', 'monitoring'],
            finding_user_assignments_attributes: [
              {
                user_id: users(:audited).id,
                process_owner: '1'
              },
              {
                user_id: users(:auditor).id,
                process_owner: '0'
              },
              {
                user_id: users(:supervisor).id,
                process_owner: '0'
              }
            ],
            work_papers_attributes: [
              {
                name: 'New workpaper name',
                code: 'PTSO 20',
                file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            ],
            finding_answers_attributes: [
              {
                answer: 'New answer',
                commitment_date: I18n.l(Date.tomorrow),
                user_id: users(:audited).id,
                file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            ],
            finding_relations_attributes: [
              {
                description: 'Duplicated',
                related_finding_id: findings(:unanswered_weakness).id
              }
            ],
            costs_attributes: [
              {
                cost: '12.5',
                cost_type: 'audit',
                description: 'New cost description',
                user_id: users(:administrator).id
              }
            ]
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_not_equal 'Updated description', finding.reload.description
  end

  test 'update finding and notify to the new user' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    assert_enqueued_emails 1 do
      patch :update, params: {
        completed: 'incomplete',
        id: finding,
        finding: {
          control_objective_item_id: control_objective_items(:impact_analysis_item).id,
          review_code: 'O020',
          title: 'Title',
          description: 'Updated description',
          answer: 'Updated answer',
          current_situation: 'Updated current situation',
          current_situation_verified: '1',
          audit_comments: 'Updated audit comments',
          state: Finding::STATUS[:unconfirmed],
          origination_date: 1.day.ago.to_date.to_s(:db),
          audit_recommendations: 'Updated proposed action',
          effect: 'Updated effect',
          risk: Finding.risks_values.first,
          priority: Finding.priorities_values.first,
          compliance: 'no',
          operational_risk: 'internal fraud',
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          users_for_notification: [users(:bare).id],
          finding_user_assignments_attributes: [
            {
              id: finding_user_assignments(:unconfirmed_weakness_bare).id,
              user_id: users(:bare).id,
              process_owner: '0'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_audited).id,
              user_id: users(:audited).id,
              process_owner: '1'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
              user_id: users(:auditor).id,
              process_owner: '0'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
              user_id: users(:supervisor).id,
              process_owner: '0'
            }
          ]
        }
      }
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_equal 'Updated description', finding.reload.description
  end

  test 'auto complete for finding relation' do
    finding = findings :being_implemented_weakness_on_draft

    get :auto_complete_for_finding_relation, params: {
      completed: 'incomplete',
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id,
      format: :json
    }

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    assert_equal 3, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001/i }
  end

  test 'auto complete for finding relation only between findings with final review' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completed: 'incomplete',
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id,
      format: :json
    }

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    # Weakness O001 it's excluded since not belongs to a final review
    assert_equal 2, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001/i }
  end

  test 'auto complete for finding relation with multiple conditions' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completed: 'incomplete',
      q: 'O001, 1 2 3',
      finding_id: finding.id,
      review_id: finding.review.id,
      format: :json
    }

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    # Just O001 from review 1 2 3
    assert_equal 1, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }
  end

  test 'auto complete for finding relation with empty results' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completed: 'incomplete',
      q: 'x_none',
      finding_id: finding.id,
      review_id: finding.review.id,
      format: :json
    }

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    assert_equal 0, findings_response.size
  end

  test 'auto complete for tagging' do
    get :auto_complete_for_tagging, params: {
      q: 'impor',
      completed: 'incomplete',
      kind: 'finding',
      format: :json
    }

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /impor/i }
  end

  test 'auto complete for tagging with empty results' do
    get :auto_complete_for_tagging, params: {
      q: 'x_none',
      completed: 'incomplete',
      kind: 'finding',
      format: :json
    }

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, tags.size
  end
end
