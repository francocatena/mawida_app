class RiskAssessmentsController < ApplicationController
  include AutoCompleteFor::BestPractice
  include AutoCompleteFor::BusinessUnit

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_title, except: [:destroy]
  before_action :set_risk_assessment, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :new_item,
    :add_items,
    :fetch_item,
    :sort_by_risk,
    :create_plan
  ]

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
    respond_with @risk_assessment, location: @risk_assessment.persisted? &&
      edit_risk_assessment_url(@risk_assessment)
  end

  # PATCH/PUT /risk_assessments/1
  def update
    update_resource @risk_assessment, risk_assessment_params

    location = if @risk_assessment.final
                 risk_assessment_url @risk_assessment
               else
                 edit_risk_assessment_url @risk_assessment
               end

    respond_with @risk_assessment, location: location
  end

  # DELETE /risk_assessments/1
  def destroy
    @risk_assessment.destroy
    respond_with @risk_assessment
  end

  # GET /risk_assessments/1/new_item
  def new_item
    @risk_assessment_item = @risk_assessment.risk_assessment_items.new

    @risk_assessment_item.build_risk_weights
  end

  # GET /risk_assessments/1/add_items
  def add_items
    @risk_assessment_items = if params[:type] == 'best_practice'
                               @risk_assessment.build_items_from_best_practices params[:ids]
                             end
  end

  # GET /risk_assessments/1/fetch_items
  def fetch_item
    id = params[:risk_assessment_item_id]
    @risk_assessment_item = @risk_assessment.risk_assessment_items.find id
  end

  # PATCH /risk_assessments/1/sort_by_risk
  def sort_by_risk
    @risk_assessment.sort_by_risk

    respond_with @risk_assessment, location: edit_risk_assessment_url(@risk_assessment)
  end

  # POST /risk_assessments/1/create_plan
  def create_plan
    plan = @risk_assessment.create_plan

    respond_with plan, location: edit_plan_url(plan)
  end

  private

    def set_risk_assessment
      @risk_assessment = RiskAssessment.list.find params[:id]
    end

    def risk_assessment_params
      params.require(:risk_assessment).permit :name, :description, :final,
        :period_id, :risk_assessment_template_id, :lock_version,
        risk_assessment_items_attributes: [
          :id, :order, :name, :business_unit_id, :process_control_id, :risk,
          :_destroy,
          risk_weights_attributes: [
            :id, :value, :weight, :risk_assessment_weight_id, :_destroy
          ]
        ]
    end

    def load_privileges
      @action_privileges.update(
        auto_complete_for_best_practice: :read,
        auto_complete_for_business_unit: :read,
        new_item: :read,
        fetch_item: :read,
        add_items: :read,
        sort_by_risk: :modify,
        create_plan: :modify
      )
    end
end
