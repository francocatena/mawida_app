require 'test_helper'

class FindingAnswerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding_answer = finding_answers :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity_auditor_answer
  end

  test 'auditor create without notification' do
    assert_no_enqueued_emails do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          auditor_comments: 'New auditor comments',
          finding: findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          user: users(:supervisor_user),
          file_model: file_models(:text_file),
          notify_users: false
        )
      end
    end
  end

  test 'audited create without notification' do
    assert_no_enqueued_emails do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          commitment_date: 10.days.from_now.to_date,
          finding: findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          user: users(:audited_user),
          file_model: file_models(:text_file),
          notify_users: false
        )
      end
    end
  end

  test 'auditor create with notification' do
    assert_enqueued_emails 1 do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          auditor_comments: 'New auditor comments',
          finding: findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          user: users(:supervisor_user),
          file_model: file_models(:text_file),
          notify_users: true
        )
      end
    end
  end

  test 'audited create with notification' do
    assert_enqueued_emails 1 do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          commitment_date: 10.days.from_now.to_date,
          finding: findings(:bcra_A4609_data_proccessing_impact_analisys_weakness),
          user: users(:audited_user),
          file_model: file_models(:text_file)
          # notify_users nil which converts to true
        )
      end
    end
  end

  test 'update' do
    assert @finding_answer.update(answer: 'New answer')

    assert_not_equal 'New answer', @finding_answer.reload.answer
  end

  test 'delete' do
    assert_difference 'FindingAnswer.count', -1 do
      @finding_answer.destroy
    end
  end

  test 'validates blank attributes with auditor' do
    @finding_answer.answer = '      '
    @finding_answer.finding_id = nil
    @finding_answer.commitment_date = ''

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :finding_id, :blank
  end

  test 'validates blank attributes with audited' do
    Organization.current_id = organizations(:cirope).id

    @finding_answer.user = users(:audited_user)
    @finding_answer.answer = ' '
    @finding_answer.finding = findings(:iso_27000_security_policy_3_1_item_weakness)
    @finding_answer.commitment_date = nil

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :commitment_date, :blank

    Organization.current_id = nil
  end

  test 'validates well formated attributes' do
    @finding_answer.commitment_date = '13/13/13'

    assert @finding_answer.invalid?
    assert_error @finding_answer, :commitment_date, :invalid_date
  end

  test 'requires commitment date' do
    Organization.current_id = organizations(:cirope).id

    @finding_answer.user = users(:audited_user)
    @finding_answer.finding = findings(:iso_27000_security_policy_3_1_item_weakness)
    @finding_answer.commitment_date = nil

    assert @finding_answer.requires_commitment_date?

    @finding_answer.finding.follow_up_date = Time.zone.today

    assert !@finding_answer.requires_commitment_date?

    @finding_answer.finding.follow_up_date = 1.day.ago

    assert @finding_answer.requires_commitment_date?

    Organization.current_id = nil
  end
end
