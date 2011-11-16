require 'test_helper'

# Clase para probar el modelo "Review"
class ReviewTest < ActiveSupport::TestCase
  fixtures :reviews, :periods, :plan_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @review = Review.find reviews(:review_with_conclusion).id
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Review, @review
    assert_equal reviews(:review_with_conclusion).identification,
      @review.identification
    assert_equal reviews(:review_with_conclusion).description,
      @review.description
  end

  # Prueba la creación de un reporte
  test 'create' do
    assert_difference 'Review.count' do
      @review = Review.create(
        :identification => 'New Identification',
        :description => 'New Description',
        :period_id => periods(:current_period).id,
        :plan_item_id => plan_items(:past_plan_item_3).id,
        :review_user_assignments_attributes => {
            :new_1 => {
              :assignment_type => ReviewUserAssignment::TYPES[:auditor],
              :user => users(:first_time_user)
            },
            :new_2 => {
              :assignment_type => ReviewUserAssignment::TYPES[:supervisor],
              :user => users(:supervisor_user)
            },
            :new_3 => {
              :assignment_type => ReviewUserAssignment::TYPES[:manager],
              :user => users(:manager_user)
            },
            :new_4 => {
              :assignment_type => ReviewUserAssignment::TYPES[:audited],
              :user => users(:audited_user)
            }
          }
      )
    end

    assert @review.score > 0
    assert @review.achieved_scale > 0
    assert @review.top_scale > 0
  end

  # Prueba de actualización de un reporte
  test 'update' do
    assert @review.update_attributes(:description => 'New description'),
      @review.errors.full_messages.join('; ')
    @review.reload
    assert_equal 'New description', @review.description
  end

  # Prueba de eliminación de un reporte
  test 'destroy' do
    assert_no_difference('Review.count') { @review.destroy }
    
    review = reviews(:review_without_conclusion_and_without_findings)
    
    assert_difference('Review.count', -1) { review.destroy }
  end

  test 'destroy with final review' do
    assert_no_difference 'Review.count' do
      Review.find(reviews(:current_review).id).destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @review.identification = nil
    @review.description = '   '
    @review.period_id = nil
    @review.plan_item_id = nil
    assert @review.invalid?
    assert_equal 4, @review.errors.count
    assert_equal [error_message_from_model(@review, :identification, :blank)],
      @review.errors[:identification]
    assert_equal [error_message_from_model(@review, :description, :blank)],
      @review.errors[:description]
    assert_equal [error_message_from_model(@review, :period_id, :blank)],
      @review.errors[:period_id]
    assert_equal [error_message_from_model(@review, :plan_item_id, :blank)],
      @review.errors[:plan_item_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @review.identification = 'abcdd' * 52
    assert @review.invalid?
    assert_equal 1, @review.errors.count
    assert_equal [error_message_from_model(@review, :identification, :too_long,
      :count => 255)], @review.errors[:identification]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @review.identification = '?nil'
    @review.period_id = '12.3'
    @review.plan_item_id = '?nil'
    assert @review.invalid?
    assert_equal 3, @review.errors.count
    assert_equal [error_message_from_model(@review, :identification, :invalid)],
      @review.errors[:identification]
    assert_equal [error_message_from_model(@review, :period_id,
        :not_an_integer)], @review.errors[:period_id]
    assert_equal [error_message_from_model(@review, :plan_item_id,
      :not_a_number)], @review.errors[:plan_item_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @review.identification = reviews(:past_review).identification
    @review.plan_item_id = reviews(:past_review).plan_item_id
    assert @review.invalid?
    assert_equal 2, @review.errors.count
    assert_equal [error_message_from_model(@review, :identification, :taken)],
      @review.errors[:identification]
    assert_equal [error_message_from_model(@review, :plan_item_id, :taken)],
      @review.errors[:plan_item_id]

    # La identificación sólo debe ser única dentro de la organización
    @review.period_id = periods(:current_period_second_organization).id
    @review.period.reload
    assert @review.invalid?
    assert_equal 1, @review.errors.count
    assert_equal [error_message_from_model(@review, :plan_item_id, :taken)],
      @review.errors[:plan_item_id]
  end

  test 'validates valid attributes' do
    @review.plan_item_id = plan_items(
      :current_plan_item_4_without_business_unit).id

    assert @review.invalid?
    assert_equal 1, @review.errors.count
    assert_equal [error_message_from_model(@review, :plan_item, :invalid)],
      @review.errors[:plan_item]
  end

  test 'can be modified' do
    uneditable_review = Review.find(reviews(:current_review).id)

    @review.description = 'Updated description'

    assert !@review.has_final_review?
    assert @review.can_be_modified?

    assert uneditable_review.has_final_review?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_review.can_be_modified?

    uneditable_review.description = 'Updated description'

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_review.can_be_modified?
    assert !uneditable_review.save

    assert_no_difference 'Review.count' do
      uneditable_review.destroy
    end
  end

  test 'review score' do
    assert !@review.control_objective_items_for_score.empty?

    cois_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end
    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end
    
    average = (total / cois_count.to_f).round

    scores = get_test_parameter(:admin_review_scores)
    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }
    count = scores.size + 1

    assert_equal average, @review.score_array.last
    assert_equal average, @review.score
    assert !@review.reload.score_text.blank?
    assert(scores.any? { |s| count -= 1; s[0] == @review.score_array.first })
    assert count > 0
    assert_equal count, @review.achieved_scale
    assert scores.size > 0
    assert_equal scores.size, @review.top_scale
    
    assert_difference '@review.control_objective_items_for_score.size', -1 do
      @review.control_objective_items.first.exclude_from_score = true
    end
    
    assert !@review.control_objective_items_for_score.empty?
    
    cois_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end
    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end
    
    new_average = (total / cois_count.to_f).round
    assert_not_equal average, new_average
  end

  test 'must be approved function' do
    @review = reviews(:review_approved_with_conclusion)
    
    assert @review.must_be_approved?
    assert @review.approval_errors.blank?

    review_weakness = @review.weaknesses.first
    finding = Weakness.new review_weakness.attributes.merge(
      'state' => Finding::STATUS[:implemented_audited],
      'review_code' => @review.next_weakness_code('O')
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    finding.solution_date = nil

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert finding.allow_destruction!
    assert finding.destroy

    finding = Weakness.new(
      finding.attributes.merge(
        'state' => Finding::STATUS[:implemented],
        'solution_date' => Date.today,
        'follow_up_date' => nil
      )
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert finding.allow_destruction!
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
        'state' => Finding::STATUS[:being_implemented]
      )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert finding.allow_destruction!
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:assumed_risk]
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save

    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?
    assert finding.allow_destruction!
    assert finding.destroy
    
    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:unconfirmed],
      'follow_up_date' => nil,
      'solution_date' => nil
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save, finding.errors.full_messages.join('; ')

    assert !@review.reload.must_be_approved?
    assert_equal 1, @review.approval_errors.size
    assert @review.can_be_approved_by_force
    assert finding.allow_destruction!
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:being_implemented],
      'follow_up_date' => Date.today,
      'solution_date' => Date.today
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    # La debilidad tiene una fecha de solución
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?

    assert finding.update_attribute(:solution_date, nil)
    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?

    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?
    @review.survey = ''
    assert !@review.must_be_approved?
    assert !@review.approval_errors.blank?

    assert @review.control_objective_items.first.update_attribute(
      :finished, false)
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?

    assert @review.control_objective_items.where(
      :finished => false
    ).first.update_attribute(:finished, true)
    assert @review.reload.must_be_approved?
    
    assert @review.finding_review_assignments.build(
      :finding_id => findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id
    )
    assert !@review.must_be_approved?
    assert @review.approval_errors.flatten.include?(
      I18n.t('review.errors.related_finding_incomplete'))
    
    assert @review.reload.must_be_approved?

    review = reviews(:review_without_conclusion_and_without_findings)
    
    review.control_objective_items.clear
    
    assert !review.must_be_approved?
    assert review.approval_errors.flatten.include?(
      I18n.t('review.errors.without_control_objectives')
    )
  end

  test 'can be sended' do
    @review = reviews(:review_approved_with_conclusion)
    
    assert @review.can_be_sended?

    review_weakness = @review.control_objective_items.first.weaknesses.first
    finding = Weakness.new review_weakness.attributes.merge(
        'state' => Finding::STATUS[:implemented_audited],
        'review_code' => @review.next_weakness_code('O')
      )
    finding.finding_user_assignments.build clone_finding_user_assignments(
      review_weakness)

    finding.solution_date = nil

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.can_be_sended?
  end

  test 'has audited function' do
    assert @review.has_audited?
    assert @review.valid?

    audited = @review.review_user_assignments.select { |rua| rua.audited? }
    @review.review_user_assignments.delete audited

    assert !@review.has_audited?
    assert @review.invalid?
  end

  test 'has manager function' do
    assert @review.has_manager?
    assert @review.valid?

    managers = @review.review_user_assignments.select { |rua| rua.manager? }
    @review.review_user_assignments.delete managers

    assert !@review.has_manager?
    assert @review.invalid?
  end

  test 'has auditor function' do
    assert @review.has_auditor?
    assert @review.valid?

    auditors = @review.review_user_assignments.select { |rua| rua.auditor? }
    @review.review_user_assignments.delete auditors

    assert !@review.has_auditor?
    assert @review.invalid?
  end

  test 'has supervisor function' do
    assert @review.has_supervisor?
    assert @review.valid?

    supervisors = @review.review_user_assignments.select {|rua| rua.supervisor?}
    @review.review_user_assignments.delete supervisors

    assert !@review.has_supervisor?
    assert @review.invalid?
  end

  test 'procedure control subitem ids' do
    assert !@review.control_objective_items.empty?
    assert_difference '@review.control_objective_items.size' do
      @review.procedure_control_subitem_ids =
        [procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id]
    end

    assert_no_difference '@review.control_objective_items.size' do
      @review.procedure_control_subitem_ids =
        [procedure_control_subitems(:procedure_control_subitem_bcra_A4609_1_1).id]
    end
  end

  test 'add a related finding from a final review' do
    assert_difference '@review.finding_review_assignments.count' do
      assert @review.update_attributes(
        :finding_review_assignments_attributes => {
          :new_1 => {
            :finding_id =>
              findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id.to_s
          }
        }
      )
    end
  end

  test 'can not add a related finding without a final review' do
    assert_no_difference '@review.finding_review_assignments.count' do
      assert_raise RuntimeError do
        @review.update_attributes(
          :finding_review_assignments_attributes => {
            :new_1 => {
              :finding_id =>
                findings(:iso_27000_security_organization_4_2_item_editable_oportunity).id.to_s
            }
          }
        )
      end
    end
  end

  test 'effectiveness function' do
    coi_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end

    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end

    assert total > 0
    assert_equal (total / coi_count.to_f).round, @review.effectiveness
  end

  test 'last control objective work paper code' do
    generated_code = @review.last_control_objective_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 00',
      @review.reload.last_control_objective_work_paper_code('New prefix')
  end

  test 'last weakness work paper code' do
    generated_code = @review.last_weakness_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code
    
    assert_equal 'New prefix 00',
      @review.reload.last_weakness_work_paper_code('New prefix')
  end

  test 'last oportunity work paper code' do
    generated_code = @review.last_oportunity_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 00',
      @review.reload.last_oportunity_work_paper_code('New prefix')
  end

  test 'last weakness code' do
    generated_code = @review.next_weakness_code('pre')
    weakness = @review.weaknesses.sort_by_code.last
    weakness_number = weakness.review_code.match(/\d+\Z/)[0].to_i
    weakness_prefix = weakness.review_code.sub(/\d+\Z/, '')

    assert_match /\Apre\d+\Z/, generated_code

    assert_equal "#{weakness_prefix}#{'%.3d' % weakness_number.next}",
      @review.reload.next_weakness_code(weakness_prefix)
    assert_equal 'New prefix001',
      @review.reload.next_weakness_code('New prefix')
  end

  test 'last oportunity code' do
    generated_code = @review.next_oportunity_code('pre')
    finding = @review.oportunities.sort_by_code.last
    oportunity_number = finding.review_code.match(/\d+\Z/)[0].to_i
    oportunity_prefix = finding.review_code.sub(/\d+\Z/, '')

    assert_match /\Apre\d+\Z/, generated_code

    assert_equal "#{oportunity_prefix}#{'%.3d' % oportunity_number.next}",
      @review.reload.next_oportunity_code(oportunity_prefix)
    assert_equal 'New prefix001',
      @review.reload.next_oportunity_code('New prefix')
  end

  test 'score sheet pdf' do
    assert_nothing_raised(Exception) do
      @review.score_sheet(organizations(:default_organization))
    end

    assert File.exist?(@review.absolute_score_sheet_path)
    assert File.size(@review.absolute_score_sheet_path) > 0

    FileUtils.rm @review.absolute_score_sheet_path
  end

  test 'global score sheet pdf' do
    assert_nothing_raised(Exception) do
      @review.global_score_sheet(organizations(:default_organization))
    end

    assert File.exist?(@review.absolute_global_score_sheet_path)
    assert File.size(@review.absolute_global_score_sheet_path) > 0

    FileUtils.rm @review.absolute_global_score_sheet_path
  end

  test 'zip all work papers' do
    assert_nothing_raised(Exception) do
      @review.zip_all_work_papers
    end

    assert File.exist?(@review.absolute_work_papers_zip_path)
    assert File.size(@review.absolute_work_papers_zip_path) > 0

    FileUtils.rm @review.absolute_work_papers_zip_path
  end

  test 'clone from' do
    new_review = Review.new
    new_review.clone_from(@review)

    assert new_review.control_objective_items.size > 0
    assert new_review.review_user_assignments.size > 0
    assert_equal @review.control_objective_items.map(&:control_objective_id).sort,
      new_review.control_objective_items.map(&:control_objective_id).sort
    assert_equal @review.review_user_assignments,
      new_review.review_user_assignments
  end
  
  private

  def clone_finding_user_assignments(finding)
    finding.finding_user_assignments.map do |fua|
      fua.attributes.dup.merge('finding_id' => nil)
    end
  end
end