module Reviews::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Current.organization&.id).order identification: :asc
    }
  end

  module ClassMethods
    def for_period period
      where period_id: period.id
    end

    def with_score_between min, max
      where score: min..max
    end

    def list_with_approved_draft
      list.
        includes(:conclusion_draft_review, :plan_item).
        merge(ConclusionReview.approved).
        references(:conclusion_reviews).
        allowed_by_business_units
    end

    def list_with_final_review
      list.
        includes(:conclusion_final_review, :plan_item).
        where.not(ConclusionReview.table_name => { review_id: nil }).
        references(:conclusion_reviews).
        allowed_by_business_units
    end

    def list_with_work_papers status: :not_finished
      initial_scope = if status == :not_finished
                        list.work_papers_not_finished
                      else
                        list.work_papers_finished
                      end

      close_date_condition =
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn 'close_date'} < ?"

      initial_scope.
        includes(:conclusion_final_review, :plan_item).
        where.not(ConclusionReview.table_name => { review_id: nil }).
        where(close_date_condition, Time.zone.today).
        allowed_by_business_units.
        references(:conclusion_reviews)
    end

    def list_without_final_review
      list.
        includes(:conclusion_final_review, :plan_item).
        where(::ConclusionReview.table_name => { review_id: nil }).
        allowed_by_business_units.
        references(:conclusion_reviews)
    end

    def list_without_draft_review
      list.
        includes(:conclusion_draft_review, :plan_item).
        where(::ConclusionReview.table_name => { review_id: nil }).
        references(:conclusion_reviews).
        allowed_by_business_units
    end

    def list_without_final_review_or_not_closed
      quoted_table = ::ConclusionReview.quoted_table_name
      conditions   = [
        "#{quoted_table}.#{ConclusionReview.qcn('review_id')} IS NULL",
        "#{quoted_table}.#{ConclusionReview.qcn('close_date')} >= :today"
      ].map { |c| "(#{c})" }.join(' OR ')

      list.
        includes(:conclusion_final_review, :plan_item).
        where(conditions, today: Time.zone.today).
        references(:conclusion_reviews).
        allowed_by_business_units
    end

    def list_all_without_final_review_by_date from_date, to_date
      start  = from_date.to_time.beginning_of_day
      finish = to_date.to_time.end_of_day

      list.includes(
        :period, :conclusion_final_review, {
          plan_item: {
            business_unit: :business_unit_type
          }
        }
      ).where(
        :created_at => start..finish,
        ConclusionReview.table_name => { review_id: nil }
      ).order(
        without_final_review_order
      ).
      allowed_by_business_units.
      references(:conclusion_reviews, :business_unit_types)
    end

    def list_all_without_workflow period_id
      list.includes(:workflow).where(
        :period_id => period_id,
        Workflow.table_name => { review_id: nil }
      ).references(:workflows)
    end

    def list_all_without_opening_interview
      list.includes(:opening_interview, :plan_item).where(
        OpeningInterview.table_name => { review_id: nil }
      ).allowed_by_business_units.
      references(:opening_interviews)
    end

    def with_opening_interview
      includes(:opening_interview).where.not(
        OpeningInterview.table_name => { review_id: nil }
      ).references(:opening_interviews)
    end

    def list_all_without_closing_interview
      list.includes(:closing_interview, :plan_item).where(
        ClosingInterview.table_name => { review_id: nil }
      ).allowed_by_business_units.
      references(:closing_interviews)
    end

    def list_by_issue_date_or_creation from_date, to_date
      start  = from_date.to_time.beginning_of_day
      finish = to_date.to_time.end_of_day

      without_final_review = list_without_final_review.where created_at: start..finish
      with_final_review    = list_with_final_review.where(
        ConclusionReview.table_name => {
          issue_date: (start.to_date)..(finish.to_date)
        }
      )

      without_final_review.or with_final_review
    end

    def allowed_by_business_units
      merge PlanItem.allowed_by_business_units
    end

    private

      def without_final_review_order
        [
          "#{Period.quoted_table_name}.#{Period.qcn('start')} ASC",
          "#{Period.quoted_table_name}.#{Period.qcn('end')} ASC",
          "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
          "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
          "#{quoted_table_name}.#{qcn('created_at')} ASC"
        ].map { |o| Arel.sql o }
      end
  end
end
