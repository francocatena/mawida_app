module AuditedReports::WeaknessesByUser
  extend ActiveSupport::Concern

  include Reports::FileResponder
  include Reports::Pdf
  include Reports::Period

  def weaknesses_by_user
    init_weaknesses_by_user_vars

    respond_to do |format|
      format.html
      format.csv  { render_weaknesses_by_user_report_csv }
    end
  end

  def create_weaknesses_by_user
    init_weaknesses_by_user_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each do |weakness|
        by_user_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.text "#{t('finding.finding_answers')}:", size: PDF_FONT_SIZE,
          style: :italic

        pdf.indent PDF_FONT_SIZE do
          weakness.finding_answers.each do |finding_answer|
            pdf.move_down PDF_FONT_SIZE * 0.5

            footer = [
              finding_answer.user.full_name,
              l(finding_answer.created_at, format: :minimal)
            ]

            pdf.text finding_answer.answer
            pdf.text footer.join(' - '), size: (PDF_FONT_SIZE * 0.75).round,
              align: :justify, color: '777777'
          end
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_audited.weaknesses_by_user.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    pdf.custom_save_as(
      t("#{@controller}_audited.weaknesses_by_user.pdf_name"), 'weaknesses_by_user', 0
    )

    @report_path = Prawn::Document.relative_path(
      t("#{@controller}_audited.weaknesses_by_user.pdf_name"), 'weaknesses_by_user', 0
    )

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  private

    def init_weaknesses_by_user_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_audited.weaknesses_by_user_title")
      @filters = []
      final = params[:final] == 'true'
      order = [
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
      ].map { |o| Arel.sql o }
      users = User.list.where id: @auth_user.self_and_descendants.map(&:id)
      weaknesses = Weakness.
        with_status_for_report.
        finals(final).
        list_for_report.
        where(state: [Finding::STATUS[:being_implemented], Finding::STATUS[:unanswered]]).
        references(:finding_user_assignments).
        joins(:finding_user_assignments).
        where(FindingUserAssignment.table_name => {
          user_id: users.map(&:id), process_owner: true
        }).
        includes(
          :business_unit,
          :business_unit_type,
          finding_answers: :user,
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:weaknesses_by_user]
        weaknesses = filter_weaknesses_by_user weaknesses
        weaknesses = filter_weaknesses_by_user_by_risk weaknesses
        weaknesses = filter_weaknesses_by_user_by_business_unit_type weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def render_weaknesses_by_user_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :by_user_csv
      )
    end

    def by_user_pdf_items weakness
      [
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          ConclusionFinalReview.human_attribute_name('issue_date'),
          l(weakness.review.conclusion_final_review.issue_date)
        ],
        [
          BusinessUnit.model_name.human,
          weakness.business_unit
        ],
        [
          Weakness.human_attribute_name('review_code'),
          weakness.review_code
        ],
        [
          Weakness.human_attribute_name('title'),
          weakness.title
        ],
        [
          Weakness.human_attribute_name('description'),
          weakness.description
        ],
        [
          Weakness.human_attribute_name('state'),
          weakness.state_text
        ],
        [
          Weakness.human_attribute_name('risk'),
          weakness.risk_text
        ],
        [
          t('finding.auditors', count: 0),
          weakness.users.select(&:auditor?).map(&:full_name).to_sentence
        ],
        [
          t('finding.responsibles', count: 1),
          weakness.process_owners.map(&:full_name).to_sentence
        ],
        [
          t('finding.audited', count: 0),
          weakness.users.select { |u|
            u.can_act_as_audited? && weakness.process_owners.exclude?(u)
          }.map(&:full_name).to_sentence
        ],
        [
          Weakness.human_attribute_name('origination_date'),
          (weakness.origination_date ? l(weakness.origination_date) : '-')
        ],
        [
          Weakness.human_attribute_name('follow_up_date'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-')
        ],
        [
          Weakness.human_attribute_name('solution_date'),
          (weakness.solution_date ? l(weakness.solution_date) : '-')
        ],
        [
          Weakness.human_attribute_name('rescheduled'),
          t("label.#{weakness.rescheduled? ? 'yes' : 'no'}")
        ],
        [
          t('findings.state.repeated'),
          t("label.#{weakness.repeated_of_id.present? ? 'yes' : 'no'}")
        ],
        [
          Weakness.human_attribute_name('audit_comments'),
          weakness.audit_comments
        ],
        [
          Weakness.human_attribute_name('audit_recommendations'),
          weakness.audit_recommendations
        ],
        [
          Weakness.human_attribute_name('answer'),
          weakness.answer
        ]
      ].compact
    end

    def filter_weaknesses_by_user weaknesses
      if params[:weaknesses_by_user][:user_id].present?
        users = User.list.where id: @auth_user.self_and_descendants.map(&:id)
        user = users.where(id: params[:weaknesses_by_user][:user_id]).take!

        @filters << "<b>#{User.model_name.human count: 1}</b> = \"#{user.full_name}\""

        weaknesses.
          references(:finding_user_assignments).
          joins(:finding_user_assignments).
          where FindingUserAssignment.table_name => {
            user_id: user.self_and_descendants.map(&:id), process_owner: true
          }
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_risk weaknesses
      risk = Array(params[:weaknesses_by_user][:risk]).reject(&:blank?).map &:to_i

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""

        weaknesses.by_risk risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_by_user][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end
end
