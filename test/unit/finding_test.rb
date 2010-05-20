require 'test_helper'

# Clase para probar el modelo "Finding"
class FindingTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding = Finding.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    finding = findings(:bcra_A4609_data_proccessing_impact_analisys_weakness)
    assert_kind_of Finding, @finding
    assert_equal finding.control_objective_item_id,
      @finding.control_objective_item_id
    assert_equal finding.review_code, @finding.review_code
    assert_equal finding.description, @finding.description
    assert_equal finding.answer, @finding.answer
    assert_equal finding.state, @finding.state
    assert_equal finding.solution_date, @finding.solution_date
    assert_equal finding.audit_recommendations, @finding.audit_recommendations
    assert_equal finding.effect, @finding.effect
    assert_equal finding.risk, @finding.risk
    assert_equal finding.priority, @finding.priority
    assert_equal finding.follow_up_date, @finding.follow_up_date
  end

  # Prueba la creación de una debilidad
  test 'create' do
    assert_difference 'Finding.count' do
      @finding = Finding.new(
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

      assert @finding.save, @finding.errors.full_messages.join('; ')
      assert_equal 'O20', @finding.review_code
    end

    # No se puede crear una observación de un objetivo que está en un informe
    # definitivo
    assert_no_difference 'Finding.count' do
      Finding.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'O20',
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
        :user_ids => [users(:bare_user).id, users(:audited_user).id,
          users(:manager_user).id, users(:supervisor_user).id]
      )
    end
  end

  # Prueba de actualización de una debilidad
  test 'update' do
    assert @finding.update_attributes(:description => 'Updated description'),
      @finding.errors.full_messages.join('; ')
    @finding.reload
    assert_equal 'Updated description', @finding.description
  end

  # Prueba de eliminación de debilidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Finding.count', -1 do
      @finding.destroy
    end

    @finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    assert_difference 'Finding.count', -1 do
      @finding.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @finding.control_objective_item_id = nil
    @finding.review_code = '   '
    @finding.description = '   '
    assert @finding.invalid?
    assert_equal 4, @finding.errors.count
    assert_equal error_message_from_model(@finding,
      :control_objective_item_id, :blank),
      @finding.errors.on(:control_objective_item_id)
    assert_equal [error_message_from_model(@finding, :review_code, :blank),
      error_message_from_model(@finding, :review_code, :invalid)].sort,
      @finding.errors.on(:review_code).sort
    assert_equal error_message_from_model(@finding, :description, :blank),
      @finding.errors.on(:description)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates special blank attributes' do
    # En estado "En proceso de implementación"
    @finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)
    @finding.follow_up_date = nil
    @finding.answer = '   '
    assert @finding.invalid?
    assert_equal 2, @finding.errors.count
    assert_equal error_message_from_model(@finding, :follow_up_date, :blank),
      @finding.errors.on(:follow_up_date)
    assert_equal error_message_from_model(@finding, :answer, :blank),
      @finding.errors.on(:answer)

    assert @finding.reload.update_attributes(
      :state => Finding::STATUS[:implemented_audited],
      :solution_date => 1.month.from_now)
    @finding.solution_date = nil
    assert @finding.invalid?
    assert_equal 1, @finding.errors.count
    assert_equal error_message_from_model(@finding, :solution_date, :blank),
      @finding.errors.on(:solution_date)
  end

  test 'validates special not blank attributes' do
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_weakness).id)

    finding.follow_up_date = Date.today
    finding.solution_date = Date.tomorrow

    assert finding.invalid?
    assert_equal 2, finding.errors.size
    assert_equal error_message_from_model(finding, :follow_up_date,
      :must_be_blank), finding.errors.on(:follow_up_date)
    assert_equal error_message_from_model(finding, :solution_date,
      :must_be_blank), finding.errors.on(:solution_date)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)
    @finding.review_code = another_finding.review_code
    assert @finding.invalid?
    assert_equal 1, @finding.errors.count
    assert_equal error_message_from_model(@finding, :review_code, :taken),
      @finding.errors.on(:review_code)

    # Se puede duplicar si es de otro informe
    another_finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    @finding.review_code = another_finding.review_code
    assert @finding.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @finding.review_code = 'abcdd' * 52
    @finding.type = 'abcdd' * 52
    assert @finding.invalid?
    assert_equal 3, @finding.errors.count
    assert_equal [error_message_from_model(@finding, :review_code, :too_long,
      :count => 255), error_message_from_model(@finding, :review_code,
      :invalid)].sort, @finding.errors.on(:review_code).sort
    assert_equal error_message_from_model(@finding, :type, :too_long,
      :count => 255), @finding.errors.on(:type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @finding.control_objective_item_id = '?nil'
    @finding.first_notification_date = '12/13/12'
    @finding.follow_up_date = '12/13/12'
    @finding.solution_date = '12/13/12'
    assert @finding.invalid?
    assert_equal 4, @finding.errors.count
    assert_equal error_message_from_model(@finding,
      :control_objective_item_id, :not_a_number),
      @finding.errors.on(:control_objective_item_id)
    assert_equal error_message_from_model(@finding, :first_notification_date,
      :invalid_date), @finding.errors.on(:first_notification_date)
    assert_equal error_message_from_model(@finding, :follow_up_date,
      :invalid_date), @finding.errors.on(:follow_up_date)
    assert_equal error_message_from_model(@finding, :solution_date,
      :invalid_date), @finding.errors.on(:solution_date)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    # Debe tener una fecha de implementación por el cambio de estado
    @finding.follow_up_date = 1.day.from_now.to_date
    @finding.state = @finding.next_status_list.values.reject do |s|
      s == @finding.state
    end.sort.last.next
    assert @finding.invalid?
    assert_equal 1, @finding.errors.count
    assert_equal error_message_from_model(@finding, :state, :inclusion),
      @finding.errors.on(:state)
  end

  test 'validates status' do
    next_status_list = @finding.next_status_list
    not_allowed_status = Finding::STATUS.values - next_status_list.values

    not_allowed_status.each do |not_allowed|
      @finding.state = not_allowed

      assert @finding.invalid?
      # Dependiendo del estado se validan más o menos cosas
      assert !@finding.errors.empty?
      assert_equal error_message_from_model(@finding, :state, :inclusion),
        @finding.errors.on(:state)
    end
  end

  test 'validates exceptional status change' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)

    finding.state = Finding::STATUS[:implemented]
    assert finding.save

    finding.state = Finding::STATUS[:being_implemented]
    assert finding.invalid?

    assert_equal error_message_from_model(finding, :state,
      :must_have_a_comment), finding.errors.on(:state)

    finding.comments.build(:comment => 'Test comment',
      :user => users(:administrator_user))
    assert finding.valid?
  end

  test 'validates audited users' do
    @finding.users.delete_if {|u| u.can_act_as_audited?}

    assert @finding.invalid?
    assert 1, @finding.errors.size
    assert_equal error_message_from_model(@finding, :users, :invalid),
      @finding.errors.on(:users)
  end

  test 'validates auditor users' do
    @finding.users.delete_if { |u| u.auditor? }

    assert @finding.invalid?
    assert 1, @finding.errors.size
    assert_equal error_message_from_model(@finding, :users, :invalid),
      @finding.errors.on(:users)
  end

  test 'validates supervisor users' do
    @finding.users.delete_if { |u| u.supervisor? }

    assert @finding.invalid?
    assert 1, @finding.errors.size
    assert_equal error_message_from_model(@finding, :users, :invalid),
      @finding.errors.on(:users)
  end

  test 'validates manager users' do
    @finding.users.delete_if { |u| u.manager? }

    assert @finding.invalid?
    assert 1, @finding.errors.size
    assert_equal error_message_from_model(@finding, :users, :invalid),
      @finding.errors.on(:users)
  end

  test 'stale function' do
    @finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)

    assert !@finding.stale?

    @finding.follow_up_date = 2.days.ago.to_date
    
    assert @finding.stale?
  end

  test 'next status list function' do
    Finding::STATUS.each do |status, value|
      @finding.state = value
      keys = @finding.next_status_list.keys
      expected_keys = Finding::STATUS_TRANSITIONS[status]

      assert_equal expected_keys.size, keys.size
      assert keys.all? { |k| expected_keys.include?(k) }
    end
  end

  test 'unconfirmed can not be changed to another than confirmed or unanswered' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    finding.state = Finding::STATUS[:implemented]

    assert !finding.update_attributes(:state => Finding::STATUS[:implemented])
    assert finding.update_attributes(:state => Finding::STATUS[:confirmed])
  end

  test 'unconfirmed to confirmed after audited response' do
    answer_type = get_test_parameter(:admin_finding_answers_types).first[1]
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)

    assert finding.unconfirmed?

    finding.finding_answers << FindingAnswer.new(
      :answer => 'New administrator answer',
      :auditor_comments => 'New auditor comments',
      :answer_type => answer_type,
      :user => users(:administrator_user)
    )

    # La respuesta es de un usuario administrador
    assert finding.unconfirmed?

    finding.finding_answers << FindingAnswer.new(
      :answer => 'New audited answer',
      :answer_type => answer_type,
      :user => users(:audited_user)
    )

    assert finding.confirmed?
    assert finding.save
  end

  test 'status change from confirmed must have an answer' do
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id)

    finding.state = Finding::STATUS[:unanswered]

    assert finding.valid?, finding.errors.full_messages.join('; ')

    finding.answer = ''

    assert finding.invalid?
    assert_equal 1, finding.errors.size
    assert_equal error_message_from_model(finding, :answer, :blank),
      finding.errors.on(:answer)
  end

  test 'dynamic functions' do
    # Funciones status?
    Finding::STATUS.each do |status, value|
      @finding.state = value
      assert @finding.send("#{status}?".to_sym)

      Finding::STATUS.each do |k, v|
        unless k == status
          @finding.state = v
          assert !@finding.send("#{status}?".to_sym)
        end
      end
    end

    # Funciones was_status?
    @finding.reload
    assert @finding.unconfirmed?

    @finding.state = Finding::STATUS[:confirmed]

    assert !@finding.unconfirmed?
    assert @finding.confirmed?
    assert @finding.was_unconfirmed?
    assert !@finding.was_confirmed?
  end

  test 'versions between' do
    assert_equal 0, @finding.versions_between(1.year.ago, 1.year.from_now).size
    assert @finding.update_attributes(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.versions_between.size
    assert_equal 1, @finding.versions_between(1.year.ago, 1.year.from_now).size
    assert_equal 0, @finding.versions_between(1.minute.from_now,
      2.minutes.from_now).size
    assert_equal 1, @finding.versions_between(1.minute.ago,
      1.minute.from_now).size
    assert_equal 0, @finding.versions_between(2.minute.ago, 1.minute.ago).size
  end

  test 'versions since final review' do
    assert_equal 0, @finding.versions_since_final_review.size
    updated_at = @finding.updated_at.dup
    assert @finding.update_attributes(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.versions_since_final_review.size
    assert_equal 0, @finding.versions_since_final_review(updated_at).size
    updated_at = @finding.reload.updated_at.dup

    assert @finding.update_attributes(:audit_comments => 'New updated comments')
    assert_equal 2, @finding.versions_since_final_review.size
    assert_equal 2, @finding.versions_since_final_review(updated_at + 1).size
    assert @finding.versions_since_final_review.first.update_attribute(
      :created_at, updated_at + 2)
    assert_equal 1, @finding.reload.versions_since_final_review(
      updated_at + 1).size
  end

  test 'status change history' do
    assert_equal 1, @finding.status_change_history.size
    assert @finding.update_attributes(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.status_change_history.size
    assert @finding.update_attributes(:state => Finding::STATUS[:confirmed])
    assert_equal 2, @finding.status_change_history.size
  end

  test 'mark as unconfirmed' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_notify_oportunity).id)

    assert finding.notify?
    assert finding.mark_as_unconfirmed!
    assert finding.unconfirmed?
    assert_equal Date.today, finding.first_notification_date
  end

  test 'important dates' do
    finding = Finding.find findings(
        :iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification).id

    assert_equal 1, finding.important_dates.size
  end

  test 'notify changes to users' do
    new_user = User.find(users(:administrator_second_user).id)

    assert !@finding.users.blank?
    assert !@finding.users.include?(new_user)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.update_attributes(:description => 'Updated description')
    end

    @finding.users.delete @finding.users.first
    @finding.users << new_user

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
  end

  test 'notify deletion of user' do
    assert !@finding.users.blank?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @finding.users.delete @finding.users.first

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
  end

  test 'has auditor and has audited' do
    assert @finding.users.any? { |u| u.can_act_as_audited? }
    assert @finding.users.any? { |u| u.auditor? }

    assert @finding.has_auditor?
    assert @finding.has_audited?

    @finding.users.delete_if { |u| u.can_act_as_audited? }

    assert @finding.has_auditor?
    assert !@finding.has_audited?

    @finding.reload.users.delete_if { |u| u.auditor? }

    assert !@finding.has_auditor?
    assert @finding.has_audited?
  end

  test 'follow up pdf' do
    assert !File.exist?(@finding.absolute_follow_up_pdf_path)

    assert_nothing_raised(Exception) do
      @finding.follow_up_pdf(organizations(:default_organization))
    end

    assert File.exist?(@finding.absolute_follow_up_pdf_path)
    assert File.size(@finding.absolute_follow_up_pdf_path) > 0

    FileUtils.rm @finding.absolute_follow_up_pdf_path
  end

  test 'to pdf' do
    assert !File.exist?(@finding.absolute_pdf_path)

    assert_nothing_raised(Exception) do
      @finding.to_pdf(organizations(:default_organization))
    end

    assert File.exist?(@finding.absolute_pdf_path)
    assert File.size(@finding.absolute_pdf_path) > 0

    FileUtils.rm @finding.absolute_pdf_path
  end

  test 'notify users if they are selected for notification' do
    @finding.users_for_notification = [users(:administrator_user).id]

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
    
    response = ActionMailer::Base.deliveries.first

    assert_equal I18n.t(:'notifier.notify_new_finding.title'), response.subject
  end

  test 'notify for stale and unconfirmed findings' do
    GlobalModelConfig.current_organization_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert_equal 2, Finding.unconfirmed_for_notification.size
    assert Finding.all(:conditions => {
        :state => Finding::STATUS[:unanswered]}).empty?

    review_codes_by_user = {}

    Finding.unconfirmed_for_notification.each do |finding|
      finding.users.each do |user|
        assert user.notifications.not_confirmed.all? {|n| !n.findings.empty?}
        review_codes_by_user[user] ||= []
        user.notifications.not_confirmed.each do |n|
          review_codes_by_user[user] |= n.findings.map(&:review_code)
        end
      end
    end

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 3 do
      Finding.notify_for_unconfirmed_for_notification_findings
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end

    Finding.unconfirmed_for_notification.each do |finding|
      begin
        finding.first_notification_date -=
          FINDING_STALE_UNCONFIRMED_DAYS.next.day
      end while [0, 6].include?(finding.first_notification_date.wday)

      assert finding.save
    end

    assert Finding.unconfirmed_for_notification.empty?
  end

  test 'warning users about findings expiration' do
    GlobalModelConfig.current_organization_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert_equal 1, Finding.next_to_expire.size
    before_expire = (FINDING_WARNING_EXPIRE_DAYS - 1).days.from_now_in_business.
      to_date
    expire = FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date

    review_codes_by_user = {}

    Finding.next_to_expire.each do |finding|
      finding.users.each do |user|
        assert !user.findings.next_to_expire.empty?
        review_codes_by_user[user] ||= []
        review_codes_by_user[user] |=
          user.findings.next_to_expire.map(&:review_code)
      end
    end

    assert(Finding.next_to_expire.all? do |finding|
      finding.follow_up_date.between?(before_expire, expire) ||
        finding.solution_date.between?(before_expire, expire)
    end)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      Finding.warning_users_about_expiration
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end
  end

  test 'mark stale and confirmed findings as unanswered' do
    GlobalModelConfig.current_organization_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    findings = Finding.confirmed_and_stale.select do |finding|
      !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
    end
    users = findings.inject([]) { |u, finding| u | finding.users }

    review_codes_by_user = {}

    users.each do |user|
      findings_by_user = user.findings.confirmed_and_stale.select do |finding|
        !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
      end

      assert !findings_by_user.empty?
      review_codes_by_user[user] = findings_by_user.map(&:review_code)
    end

    assert Finding.all(:conditions => {
        :state => Finding::STATUS[:unanswered]}).empty?
    assert_not_equal 0, findings.size

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', users.size do
      Finding.mark_as_unanswered_if_necesary
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end

    assert !Finding.all(:conditions => {
        :state => Finding::STATUS[:unanswered]}).empty?
    assert Finding.confirmed_and_stale.empty?
  end

  test 'not mark stale and confirmed findings if has an answer' do
    GlobalModelConfig.current_organization_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert Finding.all(:conditions => {
        :state => Finding::STATUS[:unanswered]}).empty?
    assert_equal 1, Finding.confirmed_and_stale.size

    Finding.confirmed_and_stale.each do |finding|
      finding.finding_answers << FindingAnswer.new(
        :answer => 'New answer',
        :auditor_comments => 'New auditor comments',
        :answer_type =>
          get_test_parameter(:admin_finding_answers_types).first[1],
        :user => users(:audited_user)
      )
    end

    assert_no_difference 'Finding.confirmed_and_stale.count' do
      Finding.mark_as_unanswered_if_necesary
    end

    assert !Finding.confirmed_and_stale.empty?
  end

  test 'work papers can be added to uneditable control objectives' do
    uneditable_finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_notify).id)

    assert_no_difference 'Finding.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_finding.update_attributes({
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
    uneditable_finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)
    uneditable_finding.final = true

    assert_no_difference ['Finding.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_finding.update_attributes({
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
end