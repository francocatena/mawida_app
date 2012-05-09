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
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
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
          t('conclusion_committee_report.synthesis_report.organization_score',
            :score => average_score || 100), (PDF_FONT_SIZE * 1.5).round)

        pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)

        pdf.text(
          t('conclusion_committee_report.synthesis_report.organization_score_note',
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
            title = t('conclusion_committee_report.synthesis_report.generic_score_average',
              :count => scores.size, :audit_type => data[:name])
            text = "<b>#{title}</b>: <i>#{(scores.sum.to_f / scores.size).round}%</i>"
          else
            text = t('conclusion_committee_report.synthesis_report.without_audits_in_the_period')
          end

          pdf.move_pointer PDF_FONT_SIZE

          pdf.text text, :font_size => PDF_FONT_SIZE
        else
          pdf.text(
            t('conclusion_committee_report.synthesis_report.without_audits_in_the_period'))
        end
      end
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.move_pointer PDF_FONT_SIZE
    pdf.text t('conclusion_committee_report.synthesis_report.references',
      :risk_types => @risk_levels.to_sentence),
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full

    pdf.custom_save_as(
      t('conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)
  end
  
  # Crea un PDF con un resumen de indicadores de calidad para un determinado
  # rango de fechas
  #
  # * GET /conclusion_committee_reports/qa_indicators
  def qa_indicators
    @title = t('conclusion_committee_report.qa_indicators_title')
    @from_date, @to_date = *make_date_range(params[:qa_indicators])
    @periods = periods_for_interval
    @columns = [
      ['indicator', t('conclusion_committee_report.qa_indicators.indicator')],
      ['value', t('conclusion_committee_report.qa_indicators.value')]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    params = { :start => @from_date, :end => @to_date }
    row_order = [:highest_solution_rate, :score_average, :production_level,
      :medium_solution_rate]
    @indicators = {}

    @periods.each do |period|
      indicators = {}
      cfrs = conclusion_reviews.for_period(period)
      
      # Production level
      reviews_count = period.plans.inject(0.0) do |pt, p|
        pt + p.plan_items.where(
          'plan_items.start >= :start AND plan_items.end <= :end', params
        ).select { |pi| pi.review.try(:has_final_review?) }.size
      end
      plan_items_count = period.plans.inject(0.0) do |pt, p|
        pt + p.plan_items.where(
          'plan_items.start >= :start AND plan_items.end <= :end', params
        ).count
      end
      
      indicators[:production_level] = plan_items_count > 0 ?
        (reviews_count / plan_items_count.to_f) * 100 : 100
      
      # Highest risk weaknesses solution rate
      pending_highest_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.final_weaknesses.with_highest_risk.where(
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
        ).count
      end

      resolved_highest_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.final_weaknesses.with_highest_risk.where(
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
        ).count
      end

      indicators[:highest_solution_rate] = pending_highest_risk > 0 ?
        (resolved_highest_risk / pending_highest_risk.to_f) * 100 : 100
      
      # Medium risk weaknesses solution rate
      pending_medium_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.final_weaknesses.where(
          'state IN(:state) AND (highest_risk - 1) = risk',
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
        ).count
      end

      resolved_medium_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.final_weaknesses.where(
          'state IN(:state) AND (highest_risk - 1) = risk',
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
        ).count
      end

      indicators[:medium_solution_rate] = pending_medium_risk > 0 ?
        (resolved_medium_risk / pending_medium_risk.to_f) * 100 : 100
      
      # Reviews score average
      indicators[:score_average] = cfrs.size > 0 ?
        (cfrs.inject(0.0) {|t, cr| t + cr.review.score.to_f} / cfrs.size.to_f) : 100

      @indicators[period] ||= []
      @indicators[period] << {
        :column_data => row_order.map do |i|
          {
            'indicator' => t("conclusion_committee_report.qa_indicators.indicators.#{i}"),
            'value' => "#{'%.1f' % indicators[i]}%"
          }
        end
      }
    end
  end

  # Crea un PDF con un resumen de indicadores de calidad para un determinado
  # rango de fechas
  #
  # * POST /conclusion_committee_reports/create_qa_indicators
  def create_qa_indicators
    self.qa_indicators

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      pdf.move_pointer PDF_FONT_SIZE
      
      @indicators[period].each do |data|
        columns = {}
        column_data = []

        @columns.each do |col_name|
          columns[col_name.first] = PDF::SimpleTable::Column.new(col_name.first) do |column|
            column.heading = col_name.last
            column.width = pdf.percent_width 50
          end
        end
        
        data[:column_data].each do |row|
          new_row = {}

          row.each do |column_name, column_content|
            new_row[column_name] = column_content.to_iso
          end

          column_data << new_row
        end

        unless column_data.blank?
          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data
            table.column_order = @columns.map(&:first)
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
        else
          pdf.text(
            t('conclusion_committee_report.qa_indicators.without_audits_in_the_period'))
        end
      end
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.qa_indicators.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'qa_indicators', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.qa_indicators.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'qa_indicators', 0)
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