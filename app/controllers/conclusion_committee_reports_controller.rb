require 'modules/conclusion_reports/conclusion_common_reports'
require 'modules/conclusion_reports/conclusion_high_risk_reports'

# =Controlador de reportes de conclusión
#
# Crea los reportes de conslusión
class ConclusionCommitteeReportsController < ApplicationController
  include ConclusionCommonReports
  include ConclusionHighRiskReports
  
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :add_weaknesses_synthesis_table,
    :get_weaknesses_synthesis_table_data, :make_date_range,
    :weaknesses_by_state, :create_weaknesses_by_state, :weaknesses_by_risk,
    :create_weaknesses_by_risk, :weaknesses_by_audit_type,
    :create_weaknesses_by_audit_type
  
  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_committee_reports
  def index
    @title = t('conclusion_committee_report.index_title')

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * GET /conclusion_committee_reports/synthesis_report
  def synthesis_report
    @title = t('conclusion_committee_report.synthesis_report_title')
    @from_date, @to_date = *make_date_range(params[:synthesis_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'review', 'score',
        'process_control', 'weaknesses_count', 'oportunities_count']
    @filters = []
    @risk_levels = []
    @audits_by_business_unit = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)

    if params[:synthesis_report]
      unless params[:synthesis_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:synthesis_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:synthesis_report][:business_unit].blank?
        business_units = params[:synthesis_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:synthesis_report][:business_unit].strip}\""
        end
      end
    end

    business_unit_types = @selected_business_unit ?
      [@selected_business_unit] : BusinessUnitType.list

    @periods.each do |period|
      business_unit_types.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'review' => [Review.model_name.human, 16],
          'score' => ["#{Review.human_attribute_name(:score)} (1)", 15],
          'process_control' =>
            ["#{BestPractice.human_attribute_name(:process_controls)} (2)", 30],
          'weaknesses_count' => ["#{t('review.weaknesses_count')} (3)", 12],
          'oportunities_count' => ["#{t('review.oportunities_count')} (4)", 12]
        }
        column_data = []
        review_scores = []
        name = but.name

        conclusion_reviews.for_period(period).each do |c_r|
          if c_r.review.business_unit.business_unit_type_id == but.id
            process_controls = {}
            weaknesses_count = {}
            
            c_r.review.control_objective_items_for_score.each do |coi|
              process_controls[coi.process_control.name] ||= []
              process_controls[coi.process_control.name] << coi
            end

            process_controls.each do |pc, control_objective_items|
              coi_count = control_objective_items.inject(0.0) do |acc, coi|
                acc + (coi.relevance || 0)
              end
              total = control_objective_items.inject(0.0) do |acc, coi|
                acc + coi.effectiveness * (coi.relevance || 0)
              end

              process_controls[pc] = coi_count > 0 ?
                (total / coi_count.to_f).round : 100
            end

            c_r.review.final_weaknesses.each do |w|
              @risk_levels |= parameter_in(@auth_organization.id,
                :admin_finding_risk_levels, w.created_at).
                sort {|r1, r2| r2[1] <=> r1[1]}.map { |r| r.first }

              weaknesses_count[w.risk_text] ||= 0
              weaknesses_count[w.risk_text] += 1
            end

           weaknesses_count_text = weaknesses_count.values.sum == 0 ?
              t(:'conclusion_committee_report.synthesis_report.without_weaknesses') :
              @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}
            process_control_text = process_controls.sort do |pc1, pc2|
              pc1[1] <=> pc2[1]
            end.map { |pc| "#{pc[0]} (#{'%.2f' % pc[1]}%)" }
            oportunities_count_text = c_r.review.final_oportunities.count > 0 ?
              c_r.review.final_oportunities.count.to_s :
              t(:'conclusion_committee_report.synthesis_report.without_oportunities')

            review_scores << c_r.review.score
            column_data << {
              'business_unit_report_name' => c_r.review.business_unit.name,
              'review' => c_r.review.to_s,
              'score' => c_r.review.reload.score_text,
              'process_control' => process_control_text,
              'weaknesses_count' => @risk_levels.blank? ?
                t(:'conclusion_committee_report.synthesis_report.without_weaknesses') :
                weaknesses_count_text,
              'oportunities_count' => oportunities_count_text
            }
          end
        end

        @audits_by_business_unit[period] ||= []
        @audits_by_business_unit[period] << {
          :name => name,
          :external => but.external,
          :columns => columns,
          :column_data => column_data,
          :review_scores => review_scores
        }
      end
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * POST /conclusion_committee_reports/create_synthesis_report
  def create_synthesis_report
    self.synthesis_report

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t(:'conclusion_committee_report.period.title'),
      t(:'conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      unless @selected_business_unit
        unless @audits_by_business_unit[period].blank?
          count = 0
          total = @audits_by_business_unit[period].inject(0) do |sum, data|
            scores = data[:review_scores]

            if scores.blank?
              sum
            else
              count += 1
              sum + (scores.sum.to_f / scores.size).round
            end
          end

          average_score = count > 0 ? (total.to_f / count).round : 100
        end

        pdf.move_pointer PDF_FONT_SIZE

        pdf.add_title(
          t(:'conclusion_committee_report.synthesis_report.organization_score',
            :score => average_score || 100), (PDF_FONT_SIZE * 1.5).round)

        pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)

        pdf.text(
          t(:'conclusion_committee_report.synthesis_report.organization_score_note',
            :audit_types => @audits_by_business_unit[period].map { |data|
              data[:name]
            }.to_sentence),
          :font_size => (PDF_FONT_SIZE * 0.75).round)
      end

      @audits_by_business_unit[period].each do |data|
        columns = data[:columns]
        column_data = []

        @column_order.each do |col_name|
          columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading = columns[col_name].first
            column.width = pdf.percent_width columns[col_name].last
          end
        end

        if !data[:external] && !@internal_title_showed
          title = t('conclusion_committee_report.synthesis_report.internal_audit_weaknesses')
          @internal_title_showed = true
        elsif data[:external] && !@external_title_showed
          title = t('conclusion_committee_report.synthesis_report.external_audit_weaknesses')
          @external_title_showed = true
        end

        if title
          pdf.move_pointer PDF_FONT_SIZE * 2
          pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
        end

        pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

        data[:column_data].each do |row|
          new_row = {}

          row.each do |column_name, column_content|
            new_row[column_name] = column_content.kind_of?(Array) ?
              column_content.map {|l| "  <C:bullet /> #{l}"}.join("\n").to_iso :
              column_content.to_iso
          end

          column_data << new_row
        end

        unless column_data.blank?
          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data.sort do |row1, row2|
              row1['score'].match(/(\d+)%/)[0].to_i <=>
                row2['score'].match(/(\d+)%/)[0].to_i
            end
            table.column_order = @column_order
            table.split_rows = true
            table.row_gap = PDF_FONT_SIZE
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_color = Color::RGB.from_percentage(95, 95, 95)
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = PDF_FONT_SIZE
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on pdf
          end

          scores = data[:review_scores]

          unless scores.blank?
            title = t(:'conclusion_committee_report.synthesis_report.generic_score_average',
              :audit_type => data[:name])
            text = "<b>#{title}</b>: <i>#{(scores.sum.to_f / scores.size).round}%</i>"
          else
            text = t(:'conclusion_committee_report.synthesis_report.without_audits_in_the_period')
          end

          pdf.move_pointer PDF_FONT_SIZE

          pdf.text text, :font_size => PDF_FONT_SIZE
        else
          pdf.text(
            t(:'conclusion_committee_report.synthesis_report.without_audits_in_the_period'))
        end
      end
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t(:'conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.move_pointer PDF_FONT_SIZE
    pdf.text t(:'conclusion_committee_report.synthesis_report.references',
      :risk_types => @risk_levels.to_sentence),
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full

    pdf.custom_save_as(
      t(:'conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update(
      :synthesis_report => :read,
      :create_synthesis_report => :read,
      :high_risk_weaknesses_report => :read,
      :create_high_risk_weaknesses_report => :read,
      :fixed_weaknesses_report => :read,
      :create_fixed_weaknesses_report => :read,
      :control_objective_stats => :read,
      :create_control_objective_stats => :read,
      :process_control_stats => :read,
      :create_process_control_stats => :read
    )
  end
end