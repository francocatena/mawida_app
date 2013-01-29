module ConclusionHighRiskReports
  # Crea un PDF con las observaciones de riesgo alto para un determinado rango
  # de fechas
  #
  # * GET /conclusion_committee_reports/high_risk_weaknesses_report
  def high_risk_weaknesses_report
    @title = t('conclusion_committee_report.high_risk_weaknesses_report_title')
    @from_date, @to_date = *make_date_range(params[:high_risk_weaknesses_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'score',
      'high_risk_weaknesses']
    @filters = []
    @notorious_reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    ).notorious(true)

    if params[:high_risk_weaknesses_report]
      unless params[:high_risk_weaknesses_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:high_risk_weaknesses_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:high_risk_weaknesses_report][:business_unit].blank?
        business_units =
          params[:high_risk_weaknesses_report][:business_unit].split(
            SPLIT_AND_TERMS_REGEXP
          ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:high_risk_weaknesses_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'high_risk_weaknesses' =>
            [t('conclusion_committee_report.high_risk_weaknesses'), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          high_risk_weaknesses = []
          weaknesses = c_r.review.final_weaknesses.with_highest_risk.
            with_pending_status_for_report

          weaknesses.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            high_risk_weaknesses << [
              "<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:follow_up_date)}</b>: #{l(w.follow_up_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}",
              "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            ].compact.join("\n")
          end

          unless high_risk_weaknesses.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              high_risk_weaknesses
            ]
          end
        end

        unless column_data.blank?
          @notorious_reviews[period] ||= []
          @notorious_reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  # Crea un PDF con las observaciones de riesgo alto para un determinado rango
  # de fechas
  #
  # * POST /conclusion_committee_reports/create_high_risk_weaknesses_report
  def create_high_risk_weaknesses_report
    self.high_risk_weaknesses_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      unless @notorious_reviews[period].blank?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
          (PDF_FONT_SIZE * 1.25).round, :left

        pdf.move_down PDF_FONT_SIZE

        @notorious_reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers, column_widths = [], [], []

          @column_order.each do |order|
            column_headers << columns[order].first
            column_widths << columns[order].last
          end
          if !data[:external] && !@internal_title_showed
            title = t('conclusion_committee_report.high_risk_weaknesses_report.internal_audit_weaknesses')
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t('conclusion_committee_report.high_risk_weaknesses_report.external_audit_weaknesses')
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          column_data = data[:column_data]
          unless column_data.blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              column_data.each do |col_data|
                column_headers.each_with_index do |header, i|
                  data = col_data[i].kind_of?(Array) ? "\n\n #{col_data[i]}" : col_data[i]
                  pdf.text "<b>#{header.upcase}</b>: #{data}", :inline_format => true
                  pdf.move_down PDF_FONT_SIZE
                end
              end
            end
          else
            pdf.text(
              t('conclusion_committee_report.high_risk_weaknesses_report.without_audits_in_the_period'),
              :style => :italic
            )
          end
        end
      end
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.high_risk_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'high_risk_weaknesses_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_committee_report.high_risk_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'high_risk_weaknesses_report', 0)
  end

  # Crea un PDF con las observaciones solucionadas para un determinado rango de
  # fechas
  #
  # * GET /conclusion_committee_reports/fixed_weaknesses_report
  def fixed_weaknesses_report
    @title = t('conclusion_committee_report.fixed_weaknesses_report_title')
    @from_date, @to_date = *make_date_range(params[:fixed_weaknesses_report])
    @periods = periods_by_solution_date_for_interval
    @column_order = ['business_unit_report_name', 'score', 'fixed_weaknesses']
    @filters = []
    @reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_final_solution_date(
      @from_date, @to_date
    )

    if params[:fixed_weaknesses_report]
      unless params[:fixed_weaknesses_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:fixed_weaknesses_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:fixed_weaknesses_report][:business_unit].blank?
        business_units = params[:fixed_weaknesses_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:fixed_weaknesses_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'fixed_weaknesses' =>
            [t('conclusion_committee_report.fixed_weaknesses'), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          fixed_weaknesses = []
          weaknesses = c_r.review.final_weaknesses.with_solution_date_between(
            @from_date, @to_date).with_highest_risk

          weaknesses.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            fixed_weaknesses << [
              "<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:solution_date)}</b>: #{l(w.solution_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}",
              "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            ].compact.join("\n")
          end

          unless fixed_weaknesses.blank?
            column_data << {
              'business_unit_report_name' => c_r.review.business_unit.name,
              'score' => c_r.review.reload.score_text,
              'fixed_weaknesses' => fixed_weaknesses
            }
          end
        end

        unless column_data.blank?
          @reviews[period] ||= []
          @reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  # Crea un PDF con las observaciones solucionadas para un determinado rango de
  # fechas
  #
  # * POST /conclusion_committee_reports/create_fixed_weaknesses_report
  def create_fixed_weaknesses_report
    self.fixed_weaknesses_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      unless @reviews[period].blank?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
          (PDF_FONT_SIZE * 1.25).round, :justify

        pdf.move_down PDF_FONT_SIZE

        @reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers, column_widths = [], [], []

          @column_order.each do |col_name|
            column_headers = col_name.first
            column_widths = pdf.percent_width col_name.last
          end

          if !data[:external] && !@internal_title_showed
            title = t('conclusion_committee_report.fixed_weaknesses_report.internal_audit_weaknesses')
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t('conclusion_committee_report.fixed_weaknesses_report.external_audit_weaknesses')
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          data[:column_data].each do |row|
            new_row = []

            row.each do |column_name, column_content|
              new_row << column_content.kind_of?(Array) ?
                column_content.join("\n\n") :
                column_content
            end

            column_data << new_row
          end

          unless column_data.blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              table_options = pdf.default_table_options(column_widths)

              pdf.table(column_data.insert(0, column_headers), table_options) do
                row(0).style(
                  :background_color => 'cccccc',
                  :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                )
              end
            end
          else
            pdf.text(
              t('conclusion_committee_report.fixed_weaknesses_report.without_audits_in_the_period'))
          end
        end
      end
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'fixed_weaknesses_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'fixed_weaknesses_report', 0)
  end

  private

  def periods_by_solution_date_for_interval
    Period.includes(:reviews => [
        :conclusion_final_review, {:control_objective_items => :final_weaknesses}]
    ).where(
      [
        "#{Weakness.table_name}.solution_date BETWEEN :from_date AND :to_date",
        "#{Period.table_name}.organization_id = :organization_id"
      ].join(' AND '),
      {
        :from_date => @from_date,
        :to_date => @to_date,
        :organization_id => @auth_organization.id
      }
    )
  end
end
