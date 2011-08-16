# =Controlador de clases de recursos
#
# Lista, muestra, crea, modifica y elimina clases de recursos (#ResourceClass) y
# sus recursos (#Resource)
class ResourceClassesController < ApplicationController
  before_filter :auth, :check_privileges
  hide_action :find_with_organization, :update_auth_user_id

  # Lista las clases de recursos
  #
  # * GET /resource_classes
  # * GET /resource_classes.xml
  def index
    @title = t :'resource_class.index_title'
    @resource_classes = ResourceClass.where(
      :organization_id => @auth_organization.id
    ).order('name ASC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resource_classes }
    end
  end

  # Muestra el detalle de una clase de recusos
  #
  # * GET /resource_classes/1
  # * GET /resource_classes/1.xml
  def show
    @title = t :'resource_class.show_title'
    @resource_class = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource_class }
    end
  end

  # Permite ingresar los datos para crear una nueva clase de recursos
  #
  # * GET /resource_classes/new
  # * GET /resource_classes/new.xml
  def new
    @title = t :'resource_class.new_title'
    @resource_class = ResourceClass.new
    @resource_class.resources.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource_class }
    end
  end

  # Recupera los datos para modificar una clase de recursos
  #
  # * GET /resource_classes/1/edit
  def edit
    @title = t :'resource_class.edit_title'
    @resource_class = find_with_organization(params[:id])
  end

  # Crea una nueva clase de recursos siempre que cumpla con las validaciones.
  # Además crea los recursos que la componen.
  #
  # * POST /resource_classes
  # * POST /resource_classes.xml
  def create
    @title = t :'resource_class.new_title'
    @resource_class = ResourceClass.new(params[:resource_class].merge(
        :organization_id => @auth_organization.id))

    respond_to do |format|
      if @resource_class.save
        flash.notice = t :'resource_class.correctly_created'
        format.html { redirect_to(resource_classes_url) }
        format.xml  { render :xml => @resource_class, :status => :created, :location => @resource_class }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @resource_class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una clase de recursos siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los recursos que la componen.
  #
  # * PUT /resource_classes/1
  # * PUT /resource_classes/1.xml
  def update
    @title = t :'resource_class.edit_title'
    @resource_class = find_with_organization(params[:id])

    respond_to do |format|
      if @resource_class.update_attributes(params[:resource_class])
        flash.notice = t :'resource_class.correctly_updated'
        format.html { redirect_to(resource_classes_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @resource_class.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'resource_class.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina una clase de recursos
  #
  # * DELETE /resource_classes/1
  # * DELETE /resource_classes/1.xml
  def destroy
    @resource_class = find_with_organization(params[:id])
    @resource_class.destroy

    respond_to do |format|
      format.html { redirect_to(resource_classes_url) }
      format.xml  { head :ok }
    end
  end

  private

  # Busca la clase de recurso indicada siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe una clase de recurso
  # con ese ID o que no pertenece a la organización con la que se autenticó el
  # usuario) devuelve nil.
  # _id_::  ID de la clase de recurso que se quiere recuperar
  def find_with_organization(id) #:doc:
    ResourceClass.where(
      :id => id, :organization_id => @auth_organization.id
    ).first(:readonly => false)
  end
end