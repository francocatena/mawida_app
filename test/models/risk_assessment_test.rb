require 'test_helper'

class RiskAssessmentTest < ActiveSupport::TestCase
  setup do
    @risk_assessment = risk_assessments :sox_current

    set_organization
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
    @risk_assessment.final!
    @risk_assessment.update name: 'new name'

    assert_not_equal 'new name', @risk_assessment.reload.name
  end

  test 'can not be destroyed when final' do
    @risk_assessment.final!

    assert_no_difference 'RiskAssessment.count' do
      @risk_assessment.destroy
    end
  end

  test 'create plan on merge' do
    @risk_assessment.update_column :period_id, periods(:unused_period).id

    Current.user = users :supervisor

    assert_difference 'Plan.count' do
      plan = @risk_assessment.merge_to_plan

      assert_equal @risk_assessment.period_id, plan.period_id
      assert_equal @risk_assessment.risk_assessment_items.count,
        plan.plan_items.count
    end

    assert @risk_assessment.reload.merged?
  ensure
    Current.user = nil
  end

  test 'append items to existing plan on merge' do
    Current.user = users :supervisor

    assert_no_difference 'Plan.count' do
      expected_count = @risk_assessment.risk_assessment_items.count

      assert_difference 'PlanItem.count', expected_count do
        plan = @risk_assessment.merge_to_plan

        assert_equal @risk_assessment.period_id, plan.period_id
      end
    end

    assert @risk_assessment.reload.merged?
  ensure
    Current.user = nil
  end

  test 'sort by risk' do
    rai = @risk_assessment.risk_assessment_items.create!(
      name:  'First by risk',
      risk:  99,
      order: 2,
      business_unit_id: business_units(:business_unit_two).id
    )

    assert_equal @risk_assessment.risk_assessment_items.last.id, rai.id

    @risk_assessment.sort_by_risk

    assert_equal @risk_assessment.reload.risk_assessment_items.first.id, rai.id
  end

  test 'build items from best practices' do
    set_organization

    bps   = [best_practices(:iso_27001), best_practices(:bcra_A4609)]
    pcs   = bps.map { |bp| bp.process_controls.where(obsolete: false).to_a }.flatten
    items = @risk_assessment.build_items_from_best_practices(bps.map &:id)

    assert_equal pcs.size, items.size
    assert pcs.all? { |pc| items.any? { |i| i.name == pc.name } }
  end

  test 'build items from business units' do
    set_organization

    buts  = [business_unit_types(:cycle), business_unit_types(:consolidated_substantive)]
    bus   = buts.map { |but| but.business_units.to_a }.flatten
    items = @risk_assessment.build_items_from_business_unit_types(buts.map &:id)

    assert_equal bus.size, items.size
    assert bus.all? { |pc| items.any? { |i| i.name == pc.name } }
  end

  test 'pdf conversion' do
    if File.exist? @risk_assessment.absolute_pdf_path
      FileUtils.rm @risk_assessment.absolute_pdf_path
    end

    assert_nothing_raised do
      @risk_assessment.to_pdf organizations(:cirope)
    end

    assert File.exist?(@risk_assessment.absolute_pdf_path)
    assert File.size(@risk_assessment.absolute_pdf_path) > 0

    FileUtils.rm @risk_assessment.absolute_pdf_path
  end

  test 'clone from' do
    new_risk_assessment = RiskAssessment.organization_scoped.new

    new_risk_assessment.clone_from @risk_assessment

    all_items_are_equal = new_risk_assessment.risk_assessment_items.all? do |rai|
      exclusion_list = %w(id risk_assessment_id risk created_at updated_at)

      @risk_assessment.risk_assessment_items.any? do |original_rai|
        rai_equal = rai.attributes.except(*exclusion_list) ==
                      original_rai.attributes.except(*exclusion_list)

        original_rai.risk_weights.all? do |orw|
          w_exclusion_list = %w(
            id risk_assessment_item_id value created_at updated_at
          )

          rai.risk_weights.any? do |rw|
            orw.attributes.except(*w_exclusion_list) ==
              rw.attributes.except(*w_exclusion_list)
          end
        end
      end
    end

    assert new_risk_assessment.risk_assessment_items.size > 0
    assert_equal @risk_assessment.risk_assessment_items.size,
      new_risk_assessment.risk_assessment_items.size
    assert all_items_are_equal
  end

  test 'clone from shared with no shared items' do
    new_risk_assessment = RiskAssessment.new organization: organizations(:google)

    new_risk_assessment.clone_from @risk_assessment

    assert new_risk_assessment.risk_assessment_template.blank?
    # Nothing gets copied here
    assert_equal 0, new_risk_assessment.risk_assessment_items.size
  end

  test 'clone from shared with shared items' do
    new_risk_assessment = RiskAssessment.new organization: organizations(:google)
    item = @risk_assessment.risk_assessment_items.take!
    process_control = process_controls :security_policy

    process_control.best_practice.update! shared: true
    item.update! process_control: process_control

    new_risk_assessment.clone_from @risk_assessment

    new_risk_assessment.risk_assessment_template =
      @risk_assessment.risk_assessment_template

    all_items_are_equal = new_risk_assessment.risk_assessment_items.all? do |rai|
      exclusion_list = %w(
        id risk_assessment_id business_unit_id risk created_at updated_at
      )

      pa = @risk_assessment.risk_assessment_items.any? do |original_rai|
        rai_equal = rai.attributes.except(*exclusion_list) ==
                      original_rai.attributes.except(*exclusion_list)

        pall = original_rai.risk_weights.all? do |orw|
          w_exclusion_list = %w(
            id risk_assessment_item_id value created_at updated_at
          )

          # All should be different, at least "on spirit"
          rai.risk_weights.all? do |rw|
            orw.attributes.except(*w_exclusion_list) !=
              rw.attributes.except(*w_exclusion_list)
          end
        end
      end
    end

    assert new_risk_assessment.risk_assessment_items.size > 0
    assert all_items_are_equal
  end
end
