# =Controlador del contenido de la ayuda en línea
#
# Lista, muestra, crea, modifica y elimina contenido de la ayuda en línea
# (#InlineHelp)
class InlineHelpsController < ApplicationController
  before_action :auth, :load_current_module
  before_action :set_inline_help, only: [
    :show, :edit, :update, :destroy
  ]

  # * GET /inline_helps
  # * GET /inline_helps.xml
  def index
    @title = t 'inline_help.index_title'
    @inline_helps = InlineHelp.order(['language ASC', 'name ASC']).paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @inline_helps }
    end
  end

  # * GET /inline_helps/1
  # * GET /inline_helps/1.xml
  def show
    @title = t 'inline_help.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @inline_help }
    end
  end

  # * GET /inline_helps/new
  # * GET /inline_helps/new.xml
  def new
    @title = t 'inline_help.new_title'
    @inline_help = InlineHelp.new(
      :language => params[:language],
      :name => params[:name]
    )
    session[:back_to] = params[:back_to]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @inline_help }
    end
  end

  # * GET /inline_helps/1/edit
  def edit
    @title = t 'inline_help.edit_title'
    session[:back_to] = params[:back_to]
  end

  # * POST /inline_helps
  # * POST /inline_helps.xml
  def create
    @title = t 'inline_help.new_title'
    @inline_help = InlineHelp.new(inline_help_params)

    respond_to do |format|
      if @inline_help.save
        flash.notice = t 'inline_help.correctly_created'
        back_to, session[:back_to] = session[:back_to], nil
        format.html { redirect_to(back_to || inline_helps_url) }
        format.xml  { render :xml => @inline_help, :status => :created, :location => @inline_help }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @inline_help.errors, :status => :unprocessable_entity }
      end
    end
  end

  # * PATCH /inline_helps/1
  # * PATCH /inline_helps/1.xml
  def update
    @title = t 'inline_help.edit_title'

    respond_to do |format|
      if @inline_help.update(inline_help_params)
        flash.notice = t 'inline_help.correctly_updated'
        back_to, session[:back_to] = session[:back_to], nil
        format.html { redirect_to(back_to || inline_helps_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @inline_help.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'inline_help.stale_object_error'
    redirect_to :action => :edit
  end

  # * DELETE /inline_helps/1
  # * DELETE /inline_helps/1.xml
  def destroy
    @inline_help.destroy

    respond_to do |format|
      format.html { redirect_to(inline_helps_url) }
      format.xml  { head :ok }
    end
  end

  private
    def set_inline_help
      @inline_help = InlineHelp.find(params[:id])
    end

    def inline_help_params
      params.require(:inline_help).permit(
        :language, :name, :content, :lock_version
      )
    end
end
