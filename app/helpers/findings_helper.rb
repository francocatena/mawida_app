module FindingsHelper
  def finding_status_field(form, inline = true, disabled = false)
    finding  = form.object
    statuses = finding.next_status_list
    excluded = []

    if finding.errors[:state].present?
      state_was = finding.new_record? ?
        Finding::STATUS[:incomplete] : Finding.find(finding.id).state

      statuses.merge! finding.next_status_list(state_was)
    end

    excluded << :repeated  unless finding.repeated?  || finding.was_repeated?
    excluded << :confirmed unless finding.confirmed? || finding.was_confirmed?

    options = statuses.except(*excluded).map do |k, v|
      [t(:"finding.status_#{k}"), v]
    end

    form.input :state, collection: sort_options_array(options), label: false,
      prompt: true, input_html: { disabled: (disabled || finding.unconfirmed?) }
  end

  def finding_repeated_of_label(form, readonly)
    if !form.object.new_record? && form.object.repeated_of && !readonly
      link = content_tag(:span,
        "[#{t('finding.undo_reiteration')}]",
        'data-help-dialog' => '#inline_undo_reiteration',
        :class => 'popup_link',
        :title => t('finding.undo_reiteration'),
        :style => 'color: #666666;'
      )

      form.label :repeated_of_id, raw(
        Finding.human_attribute_name('repeated_of_id') + ' ' +
        content_tag(:span, raw(link), :class => 'popup_link_container')
      ), :for => 'repeated_of_finding'
    else
      form.label(
        readonly && form.object.repeated_of.present? ? :repeated_of_finding : :repeated_of_id,
        Finding.human_attribute_name(:repeated_of_id)
      )
    end
  end

  def finding_repeated_of_if_field(form, readonly)
    if !form.object.new_record? && form.object.repeated_of
      form.input :repeated_of_finding, label: false, input_html: {
        value: form.object.repeated_of, disabled: true
      }
    else
      review = form.object.control_objective_item.try(:review)
      fras = (review.try(:finding_review_assignments) || []).reject do |fra|
        fra.finding.repeated? || fra.finding.class != form.object.class
      end
      findings = fras.map { |fra| [fra.finding, fra.finding_id.to_i] }
      url = url_for controller: form.object.class.to_s.tableize, action: :show, id: '[FINDING_ID]'

      form.input :repeated_of_id, collection: findings, prompt: true,
        label: false, input_html: { disabled: readonly, data: { repeated_url: url } }
    end
  end

  def finding_follow_up_date_text(finding)
    html_classes = []

    if finding.being_implemented?
      if finding.stale?
        html_classes << 'strike'
      end

      if finding.rescheduled?
        html_classes << 'text-warning'
      end

      html_classes << 'text-success' if html_classes.blank?
    end

    unless finding.follow_up_date.blank?
      content_tag(:span, l(finding.follow_up_date, :format => :short),
        :class => (html_classes.join(' ') unless html_classes.blank?))
    else
      ''
    end
  end

  def finding_updated_at_text(finding)
    label = Finding.human_attribute_name('updated_at')
    date = I18n.l(finding.updated_at, :format => :minimal) if finding.updated_at

    show_info "#{label}: #{date}"
  end

  def show_review_with_conclusion_status_as_abbr(review)
    review_data = review.has_final_review? ?
      t('review.with_final_review') : t('review.without_final_review')
    review_data << " | #{l(review.issue_date(true), :format => :long)}"

    content_tag(:abbr, h(review.identification), :title => review_data)
  end

  def show_finding_review_code_with_decription_as_abbr(finding)
    content_tag(:abbr, finding.review_code, :title => finding.description)
  end


  def finding_answer_notification_check(form)
    html_class = @auth_user.can_act_as_audited? ? 'hidden' : nil
    label = html_class.blank? && FindingAnswer.human_attribute_name(:notify_users)

    form.input :notify_users, as: :boolean, label: false, inline_label: label,
      input_html: { class: html_class }
  end

  def finding_show_status_change_history(dom_id)
    link_to(
      content_tag(
        :span, nil, class: 'glyphicon glyphicon-time', title: t('finding.show_status_change_history')
      ),
      '#', :onclick => "$('##{dom_id}').slideToggle(); return false;"
    )
  end

  def finding_responsibles_list(finding)
    users = finding.users.map do |u|
      if finding.process_owners.include?(u)
        content_tag(:b, u.full_name_with_function +
            " | #{FindingUserAssignment.human_attribute_name('process_owner')}")
      else
        u.full_name_with_function
      end
    end

    array_to_ul users
  end

  def finding_work_paper_frozen?(finding, work_paper, follow_up)
    code_prefix = follow_up ?
      t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      finding.work_paper_prefix
    follow_up_code = work_paper.code =~ /#{code_prefix}\s\d+/

    !follow_up_code && finding.review&.is_frozen?
  end

  def show_finding_answers_count(finding)
    finding_answers_count = finding.finding_answers.count
    user_answers = finding.finding_answers.where(:user_id => @auth_user.id).count
    klass = 'text-success' if user_answers > 0
    user_count = content_tag(
      :abbr, user_answers,
      :title => t('finding.user_finding_answers_count'),
      :class => klass
    )

    raw "#{finding_answers_count} / #{user_count}"
  end

  def show_finding_related_users
    users = []

    (@self_and_descendants + @related_users).each do |u|
      users << [
        u.full_name_with_function, {:user_id => u.id}.to_json
      ]

      if u.can_act_as_audited?
        users << [
          "#{u.full_name_with_function} - #{t('activerecord.attributes.finding_user_assignment.process_owner')}",
          {:user_id => u.id, :as_owner => true}.to_json
        ]
      else
        users << [
          "#{u.full_name_with_function} - #{t('activerecord.attributes.finding_user_assignment.responsible_auditor')}",
          {:user_id => u.id, :as_responsible => true}.to_json
        ]
      end
    end

    select nil, :user_id, sort_options_array(users), {:prompt => true},
      {:name => :user_id, :id => :user_id_select, :class => 'form-control'}
  end

  def finding_complete_or_incomplete_label
    t "finding.#{params[:completed]}"
  end

  def finding_status_options
    Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).map do |k, v|
      [t("finding.status_#{k}"), v.to_s]
    end
  end

  def finding_fixed_status_options
    Finding::STATUS.slice(:implemented_audited, :assumed_risk).map do |k, v|
      [t("finding.status_#{k}"), v.to_s]
    end
  end

  def finding_execution_status_options
    exclude = Finding::EXCLUDE_FROM_REPORTS_STATUS - [:unconfirmed, :confirmed]

    Finding::STATUS.except(*exclude).map do |k, v|
      [t("finding.status_#{k}"), v.to_s]
    end
  end

  def show_commitment_date? finding_answer
    finding_answer.user.can_act_as_audited? &&
      finding_answer.requires_commitment_date? &&
      !current_organization.corporate?
  end
end
