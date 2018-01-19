class RiskAssessmentsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_risk_assessment, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /risk_assessments
  def index
    build_search_conditions RiskAssessment

    @risk_assessments = RiskAssessment.list.
      includes(:period).
      references(:period).
      where(@conditions).
      order(:name).
      page params[:page]
  end

  # GET /risk_assessments/1
  def show
  end

  # GET /risk_assessments/new
  def new
    @risk_assessment = RiskAssessment.list.new
  end

  # GET /risk_assessments/1/edit
  def edit
  end

  # POST /risk_assessments
  def create
    @risk_assessment = RiskAssessment.list.new risk_assessment_params

    @risk_assessment.save
    respond_with @risk_assessment
  end

  # PATCH/PUT /risk_assessments/1
  def update
    update_resource @risk_assessment, risk_assessment_params
    respond_with @risk_assessment
  end

  # DELETE /risk_assessments/1
  def destroy
    @risk_assessment.destroy
    respond_with @risk_assessment
  end

  private

    def set_risk_assessment
      @risk_assessment = RiskAssessment.list.find params[:id]
    end

    def risk_assessment_params
      params.require(:risk_assessment).permit :name, :description, :final, :period_id, :risk_assessment_template_id, :lock_version
    end
end
