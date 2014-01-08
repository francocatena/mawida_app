class EMailsController < ApplicationController
  before_action :auth, :check_privileges

  # GET /emails
  # GET /emails.json
  def index
    @title = t 'email.index_title'

    build_search_conditions EMail

    @emails = EMail.list.where(@conditions).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @emails }
    end
  end

  # GET /emails/1
  # GET /emails/1.json
  def show
    @title = t 'email.show_title'
    @email = EMail.list.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @email }
    end
  end
end
