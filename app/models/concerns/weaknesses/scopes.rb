module Weaknesses::Scopes
  extend ActiveSupport::Concern

  included do
    scope :with_high_risk, -> {
      where(risk: highest_risks).or(with_medium_risk_and_high_priority)
    }
    scope :with_medium_risk_and_high_priority, -> {
      where risk: Finding.risks[:medium], priority: Finding.priorities[:high]
    }
    scope :with_other_risk, -> {
      where.not(risk: highest_risks).where.not(priority: Finding.priorities[:high])
    }
    scope :with_highest_risk, -> {
      where "#{quoted_table_name}.#{qcn 'highest_risk'} = #{quoted_table_name}.#{qcn 'risk'}"
    }
    scope :all_for_report, -> {
      where(
        state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values,
        final: true
      ).order(risk: :desc, state: :asc)
    }
    scope :latest, -> { where latest_id: nil }

    def process_owner_parents
      process_owners.map(&:parent).compact
    end

    def process_owner_intermediates
      process_owners.map(&:parent_intermediates).flatten
    end

    def process_owner_roots
      process_owners.map(&:parent_root).compact
    end
  end

  module ClassMethods
    def with_medium_risk risk_delta = 1
      where "#{quoted_table_name}.#{qcn 'risk'} = (#{quoted_table_name}.#{qcn 'highest_risk'} - #{risk_delta})"
    end

    def by_risk risk
      where risk: risk
    end

    def by_priority_on_risk conditions
      clauses    = []
      parameters = {}

      risks.each_with_index do |values, i|
        risk      = values.last
        priority  = conditions[values.first]
        condition = if priority
                      clauses << [
                        "#{quoted_table_name}.#{qcn 'risk'} = :risk_#{i}",
                        "#{quoted_table_name}.#{qcn 'priority'} = :priority_#{i}"
                      ].join(' AND ')

                      parameters[:"risk_#{i}"]     = risk
                      parameters[:"priority_#{i}"] = priority
                    else
                      clauses << "#{quoted_table_name}.#{qcn 'risk'} = :risk_#{i}"
                      parameters[:"risk_#{i}"] = risk
                    end
      end

      where clauses.map { |c| "(#{c})" }.join(' OR '), parameters
    end

    def by_impact impact
      where "#{quoted_table_name}.#{qcn 'impact'} && ARRAY[?]", Array(impact)
    end

    def by_operational_risk operational_risk
      column = "#{quoted_table_name}.#{qcn 'operational_risk'}"

      where "#{column} && ARRAY[?]", Array(operational_risk)
    end

    def by_internal_control_components internal_control_components
      column = "#{quoted_table_name}.#{qcn 'internal_control_components'}"

      where "#{column} && ARRAY[?]", Array(internal_control_components)
    end
  end
end
