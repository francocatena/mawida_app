require 'test_helper'

# Clase para probar el modelo "Weakness"
class WeaknessTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @weakness = Weakness.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    weakness = findings(:bcra_A4609_data_proccessing_impact_analisys_weakness)
    assert_kind_of Weakness, @weakness
    assert_equal weakness.control_objective_item_id,
      @weakness.control_objective_item_id
    assert_equal weakness.review_code, @weakness.review_code
    assert_equal weakness.description, @weakness.description
    assert_equal weakness.answer, @weakness.answer
    assert_equal weakness.state, @weakness.state
    assert_equal weakness.solution_date, @weakness.solution_date
    assert_equal weakness.audit_recommendations, @weakness.audit_recommendations
    assert_equal weakness.effect, @weakness.effect
    assert_equal weakness.risk, @weakness.risk
    assert_equal weakness.priority, @weakness.priority
    assert_equal weakness.follow_up_date, @weakness.follow_up_date
  end

  # Prueba la creación de una debilidad
  test 'create' do
    assert_difference 'Weakness.count' do
      @weakness = Weakness.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'O20',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :solution_date => nil,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
        :priority => get_test_parameter(:admin_priorities).first[1],
        :follow_up_date => nil,
        :user_ids => [users(:bare_user).id, users(:audited_user).id,
          users(:manager_user).id, users(:supervisor_user).id]
      )

      assert @weakness.save, @weakness.errors.full_messages.join('; ')
      assert_equal 'O20', @weakness.review_code
    end

    # No se puede crear una observación de un objetivo que está en un informe
    # definitivo
    assert_no_difference 'Weakness.count' do
      Weakness.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'New review code',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :solution_date => 30.days.from_now.to_date,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
        :priority => get_test_parameter(:admin_priorities).first[1],
        :follow_up_date => 2.days.from_now.to_date,
        :user_ids => [users(:bare_user).id, users(:audited_user).id]
      )
    end
  end

  # Prueba de actualización de una debilidad
  test 'update' do
    assert @weakness.update_attributes(
      :review_code => 'O20', :description => 'Updated description'),
      @weakness.errors.full_messages.join('; ')
    @weakness.reload
    assert_not_equal 'O20', @weakness.review_code
    assert_equal 'Updated description', @weakness.description
  end

  # Prueba de eliminación de debilidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Weakness.count', -1 do
      @weakness.destroy
    end

    @weakness = Weakness.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    assert_difference 'Weakness.count', -1 do
      @weakness.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @weakness.control_objective_item_id = nil
    @weakness.review_code = '   '
    @weakness.risk = nil
    @weakness.priority = nil
    assert @weakness.invalid?
    assert_equal 5, @weakness.errors.count
    assert_equal error_message_from_model(@weakness, 
      :control_objective_item_id, :blank),
      @weakness.errors.on(:control_objective_item_id)
    assert_equal [error_message_from_model(@weakness, :review_code, :blank),
      error_message_from_model(@weakness, :review_code, :invalid)].sort,
      @weakness.errors.on(:review_code).sort
    assert_equal error_message_from_model(@weakness, :risk, :blank),
      @weakness.errors.on(:risk)
    assert_equal error_message_from_model(@weakness, :priority, :blank),
      @weakness.errors.on(:priority)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)
    @weakness.review_code = another_weakness.review_code
    assert @weakness.invalid?
    assert_equal 1, @weakness.errors.count
    assert_equal error_message_from_model(@weakness, :review_code, :taken),
      @weakness.errors.on(:review_code)

    # Se puede duplicar si es de otro informe
    another_weakness = Weakness.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    @weakness.review_code = another_weakness.review_code
    assert @weakness.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @weakness.review_code = 'abcdd' * 52
    @weakness.type = 'abcdd' * 52
    assert @weakness.invalid?
    assert_equal 3, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness, :review_code, :too_long,
      :count => 255), error_message_from_model(@weakness, :review_code,
      :invalid)].sort, @weakness.errors.on(:review_code).sort
    assert_equal error_message_from_model(@weakness, :type, :too_long,
      :count => 255), @weakness.errors.on(:type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @weakness.state = Finding::STATUS.values.sort.last.next
    assert @weakness.invalid?
    assert_equal 1, @weakness.errors.count
    assert_equal error_message_from_model(@weakness, :state, :inclusion),
      @weakness.errors.on(:state)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @weakness.control_objective_item_id = '?nil'
    @weakness.review_code = 'BAD_PREFIX_2'
    assert @weakness.invalid?
    assert_equal 2, @weakness.errors.count
    assert_equal error_message_from_model(@weakness,
      :control_objective_item_id, :not_a_number),
      @weakness.errors.on(:control_objective_item_id)
    assert_equal error_message_from_model(@weakness, :review_code, :invalid),
      @weakness.errors.on(:review_code)
  end

  test 'dynamic functions' do
    Finding::STATUS.each do |status, value|
      @weakness.state = value
      assert @weakness.send("#{status}?".to_sym)

      Finding::STATUS.each do |k, v|
        unless k == status
          @weakness.state = v
          assert !@weakness.send("#{status}?".to_sym)
        end
      end
    end
  end

  test 'risk text' do
    risks = @weakness.get_parameter(:admin_finding_risk_levels)
    risk = risks.detect { |r| r.last == @weakness.risk }

    assert_equal risk.first, @weakness.risk_text
  end

  test 'priority text' do
    priorities = @weakness.get_parameter(:admin_priorities)
    priority = priorities.detect { |p| p.last == @weakness.priority }

    assert_equal priority.first, @weakness.priority_text
  end

  test 'must be approved' do
    assert @weakness.must_be_approved?
    assert @weakness.approval_errors.blank?
    assert @weakness.unconfirmed?

    @weakness.state = Finding::STATUS[:implemented_audited]
    @weakness.solution_date = nil
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t(:'weakness.errors.without_solution_date'),
      @weakness.approval_errors.first

    @weakness.state = Finding::STATUS[:implemented]
    @weakness.solution_date = 2.days.from_now.to_date
    @weakness.follow_up_date = nil
    assert !@weakness.must_be_approved?
    assert_equal 2, @weakness.approval_errors.size
    assert_equal [I18n.t(:'weakness.errors.with_solution_date'),
      I18n.t(:'weakness.errors.without_follow_up_date')].sort,
      @weakness.approval_errors.sort

    @weakness.state = Finding::STATUS[:being_implemented]
    @weakness.answer = ' '
    assert !@weakness.must_be_approved?
    assert_equal 3, @weakness.approval_errors.size
    assert_equal [I18n.t(:'weakness.errors.without_answer'),
      I18n.t(:'weakness.errors.with_solution_date'),
      I18n.t(:'weakness.errors.without_follow_up_date')].sort,
      @weakness.approval_errors.sort

    @weakness.reload
    assert @weakness.must_be_approved?
    @weakness.state = Finding::STATUS[:notify]
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t(:'weakness.errors.not_valid_state'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.users.delete_if { |user| user.audited? }
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t(:'weakness.errors.without_audited'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.users.delete_if { |user| user.auditor? }
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t(:'weakness.errors.without_auditor'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.effect = ' '
    @weakness.audit_comments = '  '
    assert !@weakness.must_be_approved?
    assert_equal 2, @weakness.approval_errors.size
    assert_equal [I18n.t(:'weakness.errors.without_effect'),
      I18n.t(:'weakness.errors.without_audit_comments')].sort,
      @weakness.approval_errors.sort
  end

  test 'work papers can be added to uneditable control objectives' do
    uneditable_weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)

    assert_no_difference 'Weakness.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_weakness.update_attributes({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'PTO 20',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :uploaded_data => ActionController::TestUploadedFile.new(
                  TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'work papers can not be added to uneditable and closed control objectives' do
    uneditable_weakness = Weakness.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)
    uneditable_weakness.final = true

    assert_no_difference ['Weakness.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_weakness.update_attributes({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'New post_workpaper code',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :uploaded_data => ActionController::TestUploadedFile.new(
                  TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'list all follow up dates and rescheduled function' do
    @weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_editable_being_implemented_oportunity).id)
    assert @weakness.all_follow_up_dates.blank?
    assert !@weakness.rescheduled?
    assert_not_nil @weakness.follow_up_date
    
    old_date = @weakness.follow_up_date.clone

    assert @weakness.update_attribute(:follow_up_date, 10.days.from_now.to_date)
    assert @weakness.reload.all_follow_up_dates.include?(old_date)
    assert @weakness.update_attribute(:follow_up_date, 15.days.from_now.to_date)
    assert @weakness.reload.all_follow_up_dates.include?(old_date)
    assert @weakness.reload.all_follow_up_dates.include?(
      10.days.from_now.to_date)
    assert @weakness.rescheduled?
  end
end