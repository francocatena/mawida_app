# =Controlador de debilidades y oportunidades de mejora
#
# Lista, muestra, modifica y elimina debilidades (#Weakness) y oportunidades de
# mejora (#Oportunity) y sus respuestas (#FindingAnswer)
class FindingsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :find_with_organization, :prepare_parameters
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las debilidades y oportunidades
  #
  # * GET /findings
  # * GET /findings.xml
  def index
    @title = t :'finding.index_title'

    options = {
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => [
        {:control_objective_item => {:review => [:period, :plan_item]}},
        :users
      ],
      :order => [
        "#{Review.table_name}.created_at DESC",
        "#{Finding.table_name}.state ASC",
        "#{Finding.table_name}.review_code ASC"
      ].join(', ')
    }
    default_conditions = {
      :final => false,
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    unless @auth_user.committee?
      default_conditions[User.table_name] = {:id => @auth_user.id}
    end
    
    default_conditions[:state] = params[:completed] == 'incomplete' ?
      Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
      Finding::STATUS.values - Finding::PENDING_STATUS
    
    build_search_conditions Finding, default_conditions

    @findings = Finding.paginate(options.merge(:conditions => @conditions))

    respond_to do |format|
      format.html {
        if @findings.size == 1 && !@query.blank?
          redirect_to edit_finding_path(params[:completed], @findings.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @findings }
    end
  end

  # Muestra el detalle de una debilidad u oportunidad
  #
  # * GET /findings/1
  # * GET /findings/1.xml
  def show
    @title = t :'finding.show_title'
    @finding = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @finding }
    end
  end

  # Recupera los datos para modificar una debilidad u oportunidad
  #
  # * GET /findings/1/edit
  def edit
    @title = t :'finding.edit_title'
    @finding = find_with_organization(params[:id])

    redirect_to findings_path unless @finding
  end

  # Actualiza el contenido de una debilidad u oportunidad siempre que cumpla con
  # las validaciones. Además actualiza el contenido de las respuestas que la
  # componen.
  #
  # * PUT /findings/1
  # * PUT /findings/1.xml
  def update
    @title = t :'finding.edit_title'
    @finding = find_with_organization(params[:id])
    params[:finding][:user_ids] ||= [] unless @finding.is_in_a_final_review?
    # Los auditados no pueden modificar desde observaciones las asociaciones
    params[:finding].delete :user_ids if @auth_user.can_act_as_audited?
    prepare_parameters

    respond_to do |format|
      Finding.transaction do
        if @finding.update_attributes(params[:finding])
          flash[:notice] = t :'finding.correctly_updated'
          format.html { redirect_to(edit_finding_path(params[:completed], @finding)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @finding.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'finding.stale_object_error'
    redirect_to :action => :edit
  end

  # Marca como eliminada una debilidad u oportunidad
  #
  # * DELETE /findings/1
  # * DELETE /findings/1.xml
  def destroy
    unless @auth_user.can_act_as_audited?
      @finding = find_with_organization(params[:id])
      @finding.destroy
    end

    respond_to do |format|
      format.html { redirect_to(findings_url(params[:completed])) }
      format.xml  { head :ok }
    end
  end


  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /oportunities/follow_up_pdf/1
  def follow_up_pdf
    finding = find_with_organization(params[:id])

    finding.follow_up_pdf(@auth_organization)

    redirect_to finding.relative_follow_up_pdf_path
  end

  # * POST /findings/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ['organizations.id = :organization_id']
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{t.downcase}%"
    end
    find_options = {
      :include => :organizations,
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ].join(','),
      :limit => 10
    }

    @users = User.all(find_options)
  end

  private

  # Busca la debilidad u oportunidad indicada siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe o que no
  # pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID de la debilidad u oportunidad que se quiere recuperar
  def find_with_organization(id) #:doc:
    options = {
      :joins => [{:control_objective_item => {:review => :period}}, :users],
      :conditions => {
        :id => id,
        :final => false,
        Period.table_name => {:organization_id => @auth_organization.id}
      },
      :readonly => false
    }

    unless @auth_user.committee?
      options[:conditions][User.table_name] = {:id => @auth_user.id}
    end
    
    finding = Finding.first(options)

    finding.finding_prefix = true if finding

    finding
  end

  # Elimina los atributos que no pueden ser modificados por usuarios
  # del tipo "Auditado".
  def prepare_parameters
    if @auth_user.can_act_as_audited?
      params[:finding].delete_if do |k,|
        ![:finding_answers_attributes, :costs_attributes].include?(k.to_sym)
      end
    end
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :follow_up_pdf => :read,
        :auto_complete_for_user => :read
      })
  end
end