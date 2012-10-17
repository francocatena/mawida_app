class PollsController < ApplicationController
  before_filter :load_privileges, :auth, :except => [:edit, :update, :show]
  before_filter :check_privileges, :except => [:edit, :update, :show]

  layout 'application'

  # GET /polls
  # GET /polls.json
  def index
    @title = t 'poll.index_title'
    if params[:id]
      @polls = Poll.by_questionnaire(params[:id]).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE)
    else
      default_conditions = {
        Poll.table_name => {:organization_id => @auth_organization.id}
      }

      build_search_conditions Poll, default_conditions

      @polls = Poll.includes(
        :questionnaire,
        :user
      ).where(@conditions).order(
        "#{Poll.table_name}.updated_at DESC"
      ).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE
      )
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @polls }
    end
  end

  # GET /polls/1
  # GET /polls/1.json
  def show
    @title = t 'poll.show_title'
    @poll = Poll.find params[:id]

    if params[:layout]
      @layout = params[:layout]
    else
      @layout = 'application'
    end

    respond_to do |format|
      if @poll.present?
        format.html { render :layout => @layout } # show.html.erb
        format.json { render :json => @poll }
      else
        format.html { redirect_to polls_url, :alert => (t 'poll.not_found') }
      end
    end
  end

  # GET /polls/new
  # GET /polls/new.json
  def new
    @title = t 'poll.new_title'
    @poll = Poll.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @poll }
    end
  end

  # GET /polls/1/edit
  def edit
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])

    if @poll.nil? || params[:token] != @poll.access_token
      redirect_to login_users_url, :alert => (t 'poll.not_found')
    elsif @poll.answered?
      redirect_to poll_path(@poll, :layout => 'application_clean'), :alert => (t 'poll.access_denied')
    end
  end

  # POST /polls
  # POST /polls.json
  def create
    @title = t 'poll.new_title'
    @poll = Poll.new(params[:poll])
    @poll.organization = @auth_organization

    respond_to do |format|
      if @poll.save
        format.html { redirect_to @poll, :notice => (t 'poll.correctly_created') }
        format.json { render :json => @poll, :status => :created, :location => @poll }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /polls/1
  # PUT /polls/1.json
  def update
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])

    respond_to do |format|
      if @poll.nil?
        format.html { redirect_to login_users_url, :alert => (t 'poll.not_found') }
      elsif @poll.update_attributes(params[:poll])
        if @auth_user
          format.html { redirect_to login_users_url, :notice => (t 'poll.correctly_updated') }
        else
          format.html { redirect_to poll_url(@poll, :layout => 'application_clean'), :notice => (t 'poll.correctly_updated') }
        end
        format.json { head :ok }
      else
        format.html { render :action => 'edit' }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'poll.stale_object_error'
    redirect_to :action => :edit
  end

  # DELETE /polls/1
  # DELETE /polls/1.json
  def destroy
    @poll = Poll.find(params[:id])
    @poll.destroy

    respond_to do |format|
      format.html { redirect_to polls_url }
      format.json { head :ok }
    end
  end

   # * GET /polls/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    conditions << "#{User.table_name}.id <> :self_id" if params[:user_id]
    parameters = {
      :organization_id => @auth_organization.id,
      :self_id => params[:user_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update(
        :auto_complete_for_user => :read
      )
    end
  end
end
