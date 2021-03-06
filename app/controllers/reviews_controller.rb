class ReviewsController < ApplicationController
  include AutoCompleteFor::BestPractice
  include AutoCompleteFor::ControlObjective
  include AutoCompleteFor::ProcessControl
  include AutoCompleteFor::Tagging

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_review, only: [
    :show, :edit, :update, :destroy, :download_work_papers, :survey_pdf,
    :finished_work_papers, :recode_findings, :recode_weaknesses_by_risk,
    :recode_weaknesses_by_repetition_and_risk,
    :recode_weaknesses_by_risk_and_repetition,
    :recode_weaknesses_by_control_objective_order, :reorder,
    :excluded_control_objectives, :reset_control_objective_name,
    :recode_work_papers
  ]
  before_action :set_review_clone, only: [:new]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista los informes
  #
  # * GET /reviews
  def index
    @title   = t 'review.index_title'
    @reviews = Review.list.
      includes(
        :conclusion_final_review, :period, :tags,
        plan_item: :business_unit,
        review_user_assignments: :user
      ).
      merge(ReviewUserAssignment.audit_team).
      references(:periods, :conclusion_final_review, :user).
      search(**search_params).
      order_by(order_param).
      page params[:page]

    respond_to do |format|
      format.html
    end
  end

  # Muestra el detalle de un informe
  #
  # * GET /reviews/1
  def show
    @title = t 'review.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.pdf  { redirect_to review_pdf_path }
    end
  end

  # Permite ingresar los datos para crear un nuevo informe
  #
  # * GET /reviews/new
  def new
    @title = t 'review.new_title'
    @review = Review.new

    @review.clone_from @review_clone if @review_clone
    @review.period_id = if params[:period]
                          params[:period].to_i
                        elsif Period.currents.list_all_with_plans.any?
                          Period.currents.list_all_with_plans.first.id
                        else
                          Period.list_all_with_plans.first.try(:id)
                        end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # Recupera los datos para modificar un informe
  #
  # * GET /reviews/1/edit
  def edit
    @title = t 'review.edit_title'
  end

  # Crea un nuevo informe siempre que cumpla con las validaciones. Además
  # actualiza el contenido de los objetivos de control que lo componen.
  #
  # * POST /reviews
  def create
    @title = t 'review.new_title'
    @review = Review.list.new(review_params)

    respond_to do |format|
      if @review.save
        flash.notice = t 'review.correctly_created'
        format.html { redirect_to(edit_review_url(@review)) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un informe siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los objetivos de control que
  # lo componen.
  #
  # * PATCH /reviews/1
  def update
    @title = t 'review.edit_title'

    respond_to do |format|
      if @review.update(review_params)
        flash.notice = t 'review.correctly_updated'
        format.html { redirect_to(edit_review_url(@review)) }
      else
        format.html { render action: :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'review.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un informe
  #
  # * DELETE /reviews/1
  def destroy
    flash.alert = t 'review.errors.can_not_be_destroyed' unless @review.destroy

    respond_to do |format|
      format.html { redirect_to(reviews_url) }
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /reviews/download_work_papers/1
  def download_work_papers
    @review.zip_all_work_papers current_organization

    redirect_to @review.relative_work_papers_zip_path
  end

  # * GET /reviews/assignment_type_refresh?user_id=1
  def assignment_type_refresh
    @user = User.find params[:user_id]

    respond_to do |format|
      format.js
    end
  end

  # * GET /reviews/plan_item_refresh?period_id=1
  def plan_item_refresh
    prefix = params[:prefix]
    business_unit_type = BusinessUnitType.list.find_by review_prefix: prefix
    plan_items = if prefix.present? && business_unit_type
                   PlanItem.for_business_unit_type business_unit_type.id
                 else
                   PlanItem.all
                 end

    grouped_plan_items = plan_items.
      list_unused(params[:period_id]).
      group_by(&:business_unit_type)

    @business_unit_types = grouped_plan_items.map do |but, plan_items|
      sorted_plan_items = plan_items.sort_by &:project

      OpenStruct.new name: but.name, plan_items: sorted_plan_items
    end

    respond_to do |format|
      format.js
    end
  end

  # Devuelve los datos del ítem del plan
  #
  # * GET /reviews/plan_item_data/1
  def plan_item_data
    @plan_item = PlanItem.find_by id: params[:id]
    @review = Review.new plan_item: @plan_item,
                         best_practice_ids: @plan_item.best_practices.ids,
                         control_objective_ids: @plan_item.control_objectives.ids

    @plan_item.human_resource_utilizations.each do |ru|
      @review.review_user_assignments.new user_id: ru.resource_id
    end
  end

  # Crea el documento de relevamiento del informe
  #
  # * GET /reviews/survey_pdf/1
  def survey_pdf
    @review.survey_pdf(current_organization)

    redirect_to @review.relative_survey_pdf_path
  end

  # Muestra sugerencias de observaciones / oportunidades de mejora reiteradas
  #
  # * GET /reviews/suggested_findings
  def suggested_findings
    plan_item = PlanItem.find(params[:id])
    @findings = Finding.where(
      [
        "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('id')} = :business_unit_id"
      ].join(' AND '),
      boolean_false: false,
      states: Finding::PENDING_FOR_REVIEW_STATUS,
      business_unit_id: plan_item.business_unit_id
    ).includes(
      control_objective_item: {
        review: [
          {plan_item: [:plan, :business_unit]},
          :period,
          :conclusion_final_review
        ]
      }
    ).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:reviews, :periods, :conclusion_reviews, :business_units)
  end

  def suggested_process_control_findings
    @process_control = ProcessControl.find params[:id]
    @findings = Finding.where(
      [
        "#{Finding.quoted_table_name}.#{Finding.qcn('organization_id')} = :organization_id",
        "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :false",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('process_control_id')} = :process_control_id"
      ].join(' AND '),
      false: false,
      organization_id: Current.organization&.id,
      states: Finding::PENDING_FOR_REVIEW_STATUS,
      process_control_id: @process_control.id
    ).includes(
      control_objective_item: [
        :control_objective, { review: :conclusion_final_review }
      ]
    ).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:reviews, :conclusion_reviews, :control_objectives)
  end

  # * GET /reviews/past_implemented_audited_findings
  def past_implemented_audited_findings
    plan_item = PlanItem.find(params[:id])
    @findings = Finding.where(
      [
        "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
        "#{Finding.quoted_table_name}.#{Finding.qcn('origination_date')} >= :limit_date",
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('id')} = :business_unit_id"
      ].join(' AND '),
      boolean_false: false,
      limit_date: 3.years.ago.to_date,
      states: [Finding::STATUS[:implemented_audited], Finding::STATUS[:expired]],
      business_unit_id: plan_item.business_unit_id
    ).includes(
      control_objective_item: {
        review: [
          {plan_item: [:plan, :business_unit]},
          :period,
          :conclusion_final_review
        ]
      }
    ).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:reviews, :periods, :conclusion_reviews, :business_units)
  end

  def auto_complete_for_past_implemented_audited_findings
    @tokens    = params[:q][0..100].split(
      SPLIT_AND_TERMS_REGEXP
    ).uniq.map(&:strip)

    @tokens.reject! { |t| t.blank? }
    conditions =
      [
        [
          "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
          "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
          "#{Finding.quoted_table_name}.#{Finding.qcn('solution_date')} >= :limit_date",
          "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL"
        ].join(' AND ')
      ].compact

      parameters = {
        boolean_false: false,
        limit_date: 3.years.ago.to_date,
        states: [Finding::STATUS[:implemented_audited], Finding::STATUS[:expired]]
      }

      @tokens.each_with_index do |t, i|
        conditions << [
          "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('review_code')}) LIKE :finding_data_#{i}",
          "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('title')}) LIKE :finding_data_#{i}",
          "LOWER(#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('control_objective_text')}) LIKE :finding_data_#{i}",
          "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')}) LIKE :finding_data_#{i}"
        ].join(' OR ')
        parameters["finding_data_#{i}".to_sym] = "%#{t.mb_chars.downcase}%"
      end

      @findings = Finding.where(
        [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
      ).includes(
        control_objective_item: {
          review: [
            { plan_item: [:plan, :business_unit] },
            :period,
            :conclusion_final_review
          ]
        }
      ).merge(
        PlanItem.allowed_by_business_units
      ).order(
        [
          "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
          "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
        ].map { |o| Arel.sql o }
      ).references(
        :reviews, :periods, :conclusion_reviews, :business_units
      ).limit(5)

      respond_to do |format|
        format.json { render json: @findings }
      end
  end

  # * GET /reviews/auto_complete_for_finding
  def auto_complete_for_finding
    @tokens = params[:q][0..100].split(
      SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
      "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
      "#{Period.quoted_table_name}.#{Period.qcn('organization_id')} = :organization_id",
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL"
    ].compact
    parameters = {
      boolean_false: false,
      organization_id: current_organization.id,
      states: Finding::PENDING_FOR_REVIEW_STATUS
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('review_code')}) LIKE :finding_data_#{i}",
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('title')}) LIKE :finding_data_#{i}",
        "LOWER(#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('control_objective_text')}) LIKE :finding_data_#{i}",
        "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')}) LIKE :finding_data_#{i}",
      ].join(' OR ')

      parameters["finding_data_#{i}".to_sym] = "%#{t.mb_chars.downcase}%"
    end

    @findings = Finding.includes(
      control_objective_item: {review: [:period, :conclusion_final_review]}
    ).where([conditions.map {|c| "(#{c})"}.join(' AND '), parameters]).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(
      :reviews, :control_objective_items, :periods, :conclusion_reviews
    ).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end

  # * GET /reviews/estimated_amount/1
  def estimated_amount
    plan_item = PlanItem.find(params[:id]) unless params[:id].blank?

    render partial: 'estimated_amount', locals: {plan_item: plan_item}
  end

  # * PUT /reviews/1/finished_work_papers
  def finished_work_papers
    is_supervisor                = @auth_user.supervisor?
    @review.finished_work_papers = if params[:revised].present? && is_supervisor
                                     'work_papers_revised'
                                   else
                                     'work_papers_finished'
                                   end

    @review.save! validate: false

    notice = if @review.work_papers_finished?
               t 'review.work_papers_marked_as_finished'
             else
               t 'review.work_papers_marked_as_revised'
             end

    redirect_to @review, notice: notice
  end

  # * PUT /reviews/1/recode_findings
  def recode_findings
    @review.recode_weaknesses
    @review.recode_oportunities

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/recode_weaknesses_by_risk
  def recode_weaknesses_by_risk
    @review.recode_weaknesses_by_risk

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/recode_weaknesses_by_repetition_and_risk
  def recode_weaknesses_by_repetition_and_risk
    @review.recode_weaknesses_by_repetition_and_risk

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/recode_weaknesses_by_risk_and_repetition
  def recode_weaknesses_by_risk_and_repetition
    @review.recode_weaknesses_by_risk_and_repetition

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/recode_weaknesses_by_control_objective_order
  def recode_weaknesses_by_control_objective_order
    @review.recode_weaknesses_by_control_objective_order

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/reorder
  def reorder
    if @review.reorder
      redirect_to @review, notice: t('review.reordered')
    else
      redirect_to edit_review_url(@review), alert: t('review.failed_to_reorder')
    end
  end

  def recode_work_papers
    if @review.recode_work_papers
      redirect_to edit_review_url(@review), notice: t('review.work_papers_recoded')
    else
      redirect_to edit_review_url(@review), alert: t('review.work_papers_recode_failed')
    end
  end

  # * GET /reviews/next_identification_number
  def next_identification_number
    @next_number = Review.list.next_identification_number params[:suffix]
  end

  def excluded_control_objectives
  end

  def reset_control_objective_name
    @control_objective_item = @review.control_objective_items.find(params[:control_objective_item_id])
    @control_objective_item.update(
      control_objective_text: @control_objective_item.control_objective.name
    )

    respond_to do |format|
      format.js
    end
  end

  private

    def review_params
      params.require(:review).permit(
        :identification, :description, :survey, :period_id, :plan_item_id,
        :scope, :risk_exposure, :manual_score, :include_sox, :lock_version,
        :score_type,
        finding_review_assignments_attributes: [
          :id, :finding_id, :_destroy, :lock_version
        ],
        review_user_assignments_attributes: [
          :id, :assignment_type, :user_id, :include_signature, :owner, :_destroy
        ],
        taggings_attributes: [
          :id, :tag_id, :_destroy
        ],
        control_objective_items_attributes: [
          :id, :control_objective_id, :control_objective_text, :relevance, :order_number, :_destroy,
          control_attributes: [
            :control, :effects, :design_tests, :compliance_tests, :sustantive_tests
          ]
        ],
        file_model_reviews_attributes: [
          :id, :_destroy,
          file_model_attributes: [:id, :file, :file_cache, :_destroy]
        ],
        control_objective_ids: [],
        process_control_ids: [],
        best_practice_ids: [],
        control_objective_tag_ids: []
      )
    end

    def set_review
      @review = Review.list.includes(
        { plan_item: :business_unit },
        { review_user_assignments: :user },
        { finding_review_assignments: :finding },
        { control_objective_items:
          [
            :control,
            { control_objective: :process_control }
          ]
        }
      ).find(params[:id])
    end

    def set_review_clone
      @review_clone = Review.list.find_by(id: params[:clone_from].try(:to_i))
    end

    def review_pdf_path
      @review.to_pdf current_organization

      @review.relative_pdf_path
    end

    def load_privileges
      @action_privileges.update(
        download_work_papers: :read,
        assignment_type_refresh: :read,
        plan_item_refresh: :read,
        plan_item_data: :read,
        survey_pdf: :read,
        suggested_findings: :read,
        suggested_process_control_findings: :read,
        past_implemented_audited_findings: :read,
        auto_complete_for_finding: :read,
        auto_complete_for_control_objective: :read,
        auto_complete_for_process_control: :read,
        auto_complete_for_best_practice: :read,
        auto_complete_for_tagging: :read,
        auto_complete_for_past_implemented_audited_findings: :read,
        estimated_amount: :read,
        next_identification_number: :read,
        excluded_control_objectives: :read,
        finished_work_papers: :modify,
        recode_findings: :modify,
        recode_weaknesses_by_risk: :modify,
        recode_weaknesses_by_repetition_and_risk: :modify,
        recode_weaknesses_by_risk_and_repetition: :modify,
        recode_weaknesses_by_control_objective_order: :modify,
        reset_control_objective_name: :modify
      )
    end
end
