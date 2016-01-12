module ControlObjectiveItemsHelper
  def control_objective_relevance_text(control_objective_item)
    relevance = control_objective_item.relevance
    text = control_objective_item.relevance_label

    text.blank? || text == '-' ? text : "#{text} (#{relevance})"
  end

  def control_objective_effectiveness(control_objective_item)
    if control_objective_item.exclude_from_score
      content_tag(
        :abbr,
        "#{control_objective_item.effectiveness}%",
        :class => 'strike',
        :title => t('control_objective_item.excluded_from_score')
      )
    else
      "#{control_objective_item.effectiveness}%"
    end
  end

  def control_objective_qualification_text(qualification, created_at)
    text = name_for_option_value(
      ControlObjectiveItem.qualifications, qualification)

    text.blank? || text == '-' ? text : "#{text} (#{qualification})"
  end

  def next_control_objective_work_paper_code(control_objective_item)
    code_from_review = next_review_work_paper_code(
      control_objective_item.review)
    code_from_control_objective = control_objective_item.work_papers.reject(
      &:marked_for_destruction?).map(&:code).sort.last

    [code_from_review, code_from_control_objective].compact.max
  end

  def control_objective_weaknesses_summary_headers
    Finding::STATUS.except(:repeated).keys.map do |status|
      content_tag :th, t("finding.status_#{status}")
    end.join
  end

  def control_objective_weaknesses_summary_row(control_objective_item)
    Finding::STATUS.except(:repeated).keys.map do |status|
      weaknesses =  control_objective_item.is_in_a_final_review? ?
        control_objective_item.final_weaknesses :
        control_objective_item.weaknesses
      weaknesses_count = weaknesses.select { |w| w.send "#{status}?" }.size

      content_tag :td, weaknesses_count
    end.join
  end

  def control_objective_oportunities_summary_headers
    Finding::STATUS.except(:repeated).keys.map do |status|
      content_tag :th, t("finding.status_#{status}")
    end.join
  end

  def control_objective_oportunities_summary_row(control_objective_item)
    Finding::STATUS.except(:repeated).keys.map do |status|
      oportunities =  control_objective_item.is_in_a_final_review? ?
        control_objective_item.final_oportunities :
        control_objective_item.oportunities
      oportunities_count = oportunities.select { |w| w.send "#{status}?" }.size

      content_tag :td, oportunities_count
    end.join
  end

  def control_objective_weaknesses_link(control_objective_item)
    weaknesses = control_objective_item.is_in_a_final_review? ?
      control_objective_item.final_weaknesses : control_objective_item.weaknesses

    link_to_unless weaknesses.count == 0, weaknesses.count,
      weaknesses_path(:control_objective => control_objective_item)
  end
end
