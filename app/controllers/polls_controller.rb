class PollsController < ApplicationController
  before_action :load_privileges, :auth, except: [:edit, :update, :show]
  before_action :check_privileges, except: [:edit, :update, :show]
  before_action :set_poll, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  respond_to :html

  require 'csv'

  # GET /polls
  # GET /polls.json
  def index
    @current_module = 'administration_questionnaires_polls'

    build_search_conditions Poll

    @polls = Poll.list.includes(:questionnaire, :user).
      where(@conditions).order("#{Poll.table_name}.created_at DESC").
      references(:questionnaire, :user).page(params[:page])

    respond_with @polls
  end

  # GET /polls/1
  def show
  end

  # GET /polls/new
  def new
    @poll = Poll.new
  end

  # GET /polls/1/edit
  def edit
    if @poll.nil?
      redirect_to login_url, alert: t('poll.not_found')
    elsif @poll.answered? || (params[:token] != @poll.access_token)
      redirect_to @poll
    end
  end

  # POST /polls
  def create
    @poll = Poll.list.new poll_params

    @poll.save
    respond_with @poll
  end

  # PATCH /polls/1
  def update
    update_resource @poll, poll_params
    respond_with @poll, location: poll_url(@poll) unless response_body
  end

  # DELETE /polls/1
  def destroy
    @poll.destroy
    respond_with @poll
  end

  def reports
    @title = t 'poll.reports_title'
  end

  def import_csv_customers
    @title = t('poll.import_csv_customers_title')
  end

  def auto_complete_for_user
    @users = current_organization.users.where(hidden: false).
      search(params[:q]).limit(10)

    respond_to do |format|
      format.json { render json: @users }
    end
  end

  def send_csv_polls
    ext = File.extname(params[:dump_emails][:file].original_filename) rescue ''

    if ext.downcase == '.csv'
      uploaded_file = params[:dump_emails][:file]
      file_name = uploaded_file.path
      questionnaire_id = params[:dump_emails][:questionnaire_id].to_i

      text = File.read(file_name, { encoding: 'UTF-8', delimiter: ';' })

      @parsed_file = CSV.parse(text)
      n = 0

      @parsed_file.each  do |row|
        poll = Poll.new(
          questionnaire_id: questionnaire_id,
          organization_id: current_organization.id
        )
        poll.customer_email = row[0]
        poll.customer_name = row[1]

        if poll.save
          n+=1
        end
      end

      flash[:notice] = t('poll.customer_polls_sended', count: n)
    else
      flash[:alert] = t('poll.error_csv_file_extension')
    end

    respond_to do |format|
      format.html { redirect_to polls_path }
    end
  end

  private

    def poll_params
      params.require(:poll).permit(
        :user_id, :questionnaire_id, :comments, :lock_version,
        answers_attributes: [
          :id, :answer, :comments, :answer_option_id, :type
        ]
      )
    end

    def set_poll
      @poll = Poll.list.find(params[:id])
    end

    def load_privileges
      if @action_privileges
        @action_privileges.update(
          reports: :read,
          auto_complete_for_user: :read,
          import_csv_customers: :read
        )
      end
    end
end
