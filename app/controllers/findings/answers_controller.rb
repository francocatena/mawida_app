class Findings::AnswersController < ApplicationController
  include Findings::SetFinding

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_finding, only: [:create]

  def create
    @finding_answer = @finding.finding_answers.create finding_answer_params

    flash.notice = t 'flash.finding_answers.create.notice' if @finding_answer.persisted?

    respond_with @finding_answer, location: finding_url(params[:completed], @finding)
  end

  private

    def finding_answer_params
      params.require(:finding_answer).permit(
        :answer, :user_id, :commitment_date, :notify_users,
        file_model_attributes: [:file, :file_cache]
      )
    end

    def scoped_findings
      current_organization.corporate? ? Finding.group_list : Finding.list
    end

    def load_privileges
      @action_privileges.update create: :read
    end
end
