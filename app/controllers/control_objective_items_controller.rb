# =Controlador de objetivos de control
#
# Lista, muestra, modifica y elimina objetivos de control
# (#ControlObjectiveItem)
class ControlObjectiveItemsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_control_objective_item, only: [
    :show, :edit, :update, :destroy
  ]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los objetivos de control
  #
  # * GET /control_objective_items
  # * GET /control_objective_items.xml
  def index
    @title = t 'control_objective_item.index_title'
    default_conditions = {
      Period.table_name => {organization_id: current_organization.id}
    }

    build_search_conditions ControlObjectiveItem, default_conditions

    @control_objectives = ControlObjectiveItem.includes(
        :weaknesses,
        :work_papers,
        {review: :period},
        {control_objective: :process_control}
    ).where(@conditions).order(
      "#{Review.table_name}.identification DESC"
    ).paginate(page: params[:page], per_page: APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @control_objectives.size == 1 && !@query.blank? && !params[:page]
          redirect_to control_objective_item_url(@control_objectives.first)
        end
      } # index.html.erb
      format.xml  { render xml: @control_objective_items }
    end
  end

  # Muestra el detalle de un objetivo de control
  #
  # * GET /control_objective_items/1
  # * GET /control_objective_items/1.xml
  def show
    @title = t 'control_objective_item.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @control_objective_item }
    end
  end

  # Recupera los datos para modificar un objetivo de control
  #
  # * GET /control_objective_items/1/edit
  def edit
    @title = t 'control_objective_item.edit_title'
    
    if params[:control_objective] && params[:review]
      @control_objective_item = ControlObjectiveItem.includes(:review).where(
        control_objective_id: params[:control_objective],
        review_id: params[:review],
        Review.table_name => {organization_id: current_organization.id}
      ).order('created_at DESC').first
      session[:back_to] = edit_review_url(params[:review].to_i)
    end

    @review = @control_objective_item.review
  end

  # Actualiza el contenido de un objetivo de control siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /control_objective_items/1
  # * PATCH /control_objective_items/1.xml
  def update
    @title = t 'control_objective_item.edit_title'
    review = @control_objective_item.review

    respond_to do |format|
      updated = review.update(
        control_objective_items_attributes: {
          @control_objective_item.id => control_objective_item_params.merge(
            id: @control_objective_item.id
          )
        }
      )
      # Se carga el objetivo del informe para poder reportar los errores
      @control_objective_item = review.control_objective_items.detect do |coi|
        coi.id == @control_objective_item.id
      end
      
      if updated
        flash.notice = t 'control_objective_item.correctly_updated'
        back_to, session[:back_to] = session[:back_to], nil
        format.html {
          redirect_to(back_to || edit_control_objective_item_url(@control_objective_item))
        }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @control_objective_item.errors, status: :unprocessable_entity }
      end
    end

    rescue ActiveRecord::StaleObjectError
      flash.alert = t 'control_objective_item.stale_object_error'
      redirect_to action: :edit
  end

  # Elimina un objetivo de control
  #
  # * DELETE /control_objective_items/1
  # * DELETE /control_objective_items/1.xml
  def destroy
    @control_objective_item.destroy

    respond_to do |format|
      format.html {
        redirect_to(control_objective_items_url(params.slice(:period, :review)))
      }
      format.xml  { head :ok }
    end
  end

  private
    def set_control_objective_item
      @control_objective_item = ControlObjectiveItem.includes(
        :control, :weaknesses, :work_papers, { review: :period }
      ).where(
        id: params[:id], Period.table_name => { organization_id: current_organization.id }
      ).first
    end

    def control_objective_item_params
      params.require(:control_objective_item).permit(
        :control_objective_text, :relevance, :design_score, :compliance_score, :sustantive_score,
        :audit_date, :auditor_comment, :control_objective_id, :review_id, :finished,
        :exclude_from_score, :lock_version,
        :lock_version, control_attributes: [
          :id, :control, :effects, :design_tests, :compliance_tests,
          :sustantive_tests
        ], work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy, :lock_version,
          file_model_attributes: [:id, :file, :file_cache]
        ]
      )
    end
end
