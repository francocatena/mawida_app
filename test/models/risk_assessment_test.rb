require 'test_helper'

class RiskAssessmentTest < ActiveSupport::TestCase
  setup do
    @risk_assessment = risk_assessments :sox_current
  end

  test 'blank attributes' do
    @risk_assessment.name = ''
    @risk_assessment.description = ''
    @risk_assessment.period = nil
    @risk_assessment.risk_assessment_template = nil

    assert @risk_assessment.invalid?
    assert_error @risk_assessment, :name, :blank
    assert_error @risk_assessment, :description, :blank
    assert_error @risk_assessment, :period, :blank
    assert_error @risk_assessment, :risk_assessment_template, :blank
  end

  test 'unique attributes' do
    risk_assessment = @risk_assessment.dup

    assert risk_assessment.invalid?
    assert_error risk_assessment, :name, :taken
    assert_error risk_assessment, :period_id, :taken
  end

  test 'attribute length' do
    @risk_assessment.name = 'abcde' * 52

    assert @risk_assessment.invalid?
    assert_error @risk_assessment, :name, :too_long, count: 255
  end

  test 'validates attributes encoding' do
    @risk_assessment.name = "\n\t"
    @risk_assessment.description = "\n\t"

    assert @risk_assessment.invalid?
    assert_error @risk_assessment, :name, :pdf_encoding
    assert_error @risk_assessment, :description, :pdf_encoding
  end

  test 'can not be updated when final' do
    @risk_assessment.update! final: true
    @risk_assessment.update name: 'new name'

    assert_not_equal 'new name', @risk_assessment.reload.name
  end

  test 'can not be destroyed when final' do
    @risk_assessment.update! final: true

    assert_no_difference 'RiskAssessment.count' do
      @risk_assessment.destroy
    end
  end

  test 'create plan' do
    @risk_assessment.update_column :period_id, periods(:unused_period).id

    assert_difference 'Plan.count' do
      plan = @risk_assessment.create_plan

      assert_equal @risk_assessment.period_id, plan.period_id
      assert_equal @risk_assessment.risk_assessment_items.count,
        plan.plan_items.count
    end
  end
end
