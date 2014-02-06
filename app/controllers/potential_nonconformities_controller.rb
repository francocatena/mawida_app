class PotentialNonconformitiesController < ApplicationController
  include AutoCompleteFor::User
  include AutoCompleteFor::FindingRelation

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_potential_nonconformity, only: [
    :show, :edit, :update, :destroy, :follow_up_pdf, :undo_reiteration
  ]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las no conformidades potenciales
  #
  # * GET /potential_nonconformities
  # * GET /potential_nonconformities.xml
  def index
    @title = t 'potential_nonconformity.index_title'
    default_conditions = [
      [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{PotentialNonconformity.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{PotentialNonconformity.table_name}.final = :boolean_true"
        ].join(' AND ')
      ].map {|condition| "(#{condition})"}.join(' OR ')
    ]
    parameters = { boolean_true: true, boolean_false: false }

    if params[:control_objective].to_i > 0
      default_conditions << "#{Weakness.table_name}.control_objective_item_id = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:review].to_i > 0
      default_conditions << "#{Review.table_name}.id = :review_id"
      parameters[:review_id] = params[:review].to_i
    end

    build_search_conditions PotentialNonconformity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @potential_nonconformities = PotentialNonconformity.list.includes(
      :work_papers,
      control_objective_item: {
        review: [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{PotentialNonconformity.table_name}.review_code ASC"
      ]
    ).page(params[:page])

    respond_to do |format|
      format.html {
        if @potential_nonconformities.size == 1 && !@query.blank? && !params[:page]
          redirect_to potential_nonconformity_url(@potential_nonconformities.first)
        end
      } # index.html.erb
      format.xml  { render xml: @potential_nonconformities }
    end
  end

  # Muestra el detalle de una no conformidad potencial
  #
  # * GET /potential_nonconformities/1
  # * GET /potential_nonconformities/1.xml
  def show
    @title = t 'potential_nonconformity.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @potential_nonconformity }
    end
  end

  # Permite ingresar los datos para crear una nueva no conformidad potencial
  #
  # * GET /potential_nonconformities/new
  # * GET /potential_nonconformities/new.xml
  def new
    @title = t 'potential_nonconformity.new_title'
    @potential_nonconformity = PotentialNonconformity.new(
      {control_objective_item_id: params[:control_objective_item]}, {}, true
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @potential_nonconformity }
    end
  end

  # Recupera los datos para modificar una no conformidad potencial
  #
  # * GET /potential_nonconformities/1/edit
  def edit
    @title = t 'potential_nonconformity.edit_title'
  end

  # Crea una no conformidad potencial siempre que cumpla con las validaciones.
  #
  # * POST /potential_nonconformities
  # * POST /potential_nonconformities.xml
  def create
    @title = t 'potential_nonconformity.new_title'
    @potential_nonconformity = PotentialNonconformity.list.new(potential_nonconformity_params)

    respond_to do |format|
      if @potential_nonconformity.save
        flash.notice = t 'potential_nonconformity.correctly_created'
        format.html { redirect_to(edit_potential_nonconformity_url(@potential_nonconformity)) }
        format.xml  { render xml: @potential_nonconformity, status: :created, location: @potential_nonconformity }
      else
        format.html { render action: :new }
        format.xml  { render xml: @potential_nonconformity.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una no conformidad potential siempre que cumpla con
  # las validaciones.
  #
  # * PATCH /potential_nonconformities/1
  # * PATCH /potential_nonconformities/1.xml
  def update
    @title = t 'potential_nonconformity.edit_title'

    respond_to do |format|
      PotentialNonconformity.transaction do
        if @potential_nonconformity.update(potential_nonconformity_params)
          flash.notice = t 'potential_nonconformity.correctly_updated'
          format.html { redirect_to(edit_potential_nonconformity_url(@potential_nonconformity)) }
          format.xml  { head :ok }
        else
          format.html { render action: :edit }
          format.xml  { render xml: @potential_nonconformity.errors, status: :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'potential_nonconformity.stale_object_error'
    redirect_to action: :edit
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /potential_nonconformities/follow_up_pdf/1
  def follow_up_pdf
    @potential_nonconformity.follow_up_pdf(current_organization)
    redirect_to @potential_nonconformity.relative_follow_up_pdf_path
  end

  # Deshace la reiteración de la oportunidad
  #
  # * PATCH /potential_nonconformities/undo_reiteration/1
  def undo_reiteration
    @potential_nonconformity.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_potential_nonconformity_url(@potential_nonconformity)) }
      format.xml  { head :ok }
    end
  end

  # * POST /potential_nonconformities/auto_complete_for_control_objective_item
  def auto_complete_for_control_objective_item
    @tokens = params[:q][0..100].split(SEARCH_AND_REGEXP).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      "#{ConclusionReview.table_name}.review_id IS NULL",
      "#{ControlObjectiveItem.table_name}.review_id = :review_id"
    ]
    parameters = {
      organization_id: current_organization.id,
      review_id: params[:review_id].to_i
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :control_objective_item_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_item_data_#{i}"] =
        "%#{Unicode::downcase(t)}%"
    end

    @control_objective_items = ControlObjectiveItem.includes(
      review: [:period, :conclusion_final_review]
    ).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order("#{Review.table_name}.identification ASC").limit(10)

    respond_to do |format|
      format.json { render json: @control_objective_items }
    end
  end

  private
    def potential_nonconformity_params
      params.require(:potential_nonconformity).permit(
        :control_objective_item_id, :review_code, :description, :answer, :audit_comments,
        :cause_analysis, :cause_analysis_date, :correction, :correction_date,
        :state, :follow_up_date, :solution_date, :lock_version, :repeated_of_id,
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ]
      )
    end

    def set_potential_nonconformity
      @potential_nonconformity = PotentialNonconformity.list.includes(
        :finding_relations, :work_papers,
        { finding_user_assignments: :user },
        { control_objective_item: { review: :period } }
      ).find(params[:id])
    end

    def load_privileges
      @action_privileges.update(
        follow_up_pdf: :read,
        auto_complete_for_user: :read,
        auto_complete_for_finding_relation: :read,
        auto_complete_for_control_objective_item: :read,
        undo_reiteration: :modify
      )
    end
end
