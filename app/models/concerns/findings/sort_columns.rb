module Findings::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods
    def columns_for_sort
      columns = {
        risk_asc:            risk_asc_options,
        risk_desc:           risk_desc_options,
      }.with_indifferent_access

      columns.merge!(
        priority_asc:        priority_asc_options,
        priority_desc:       priority_desc_options,
      ) unless HIDE_WEAKNESSES_PRIORITY

      columns.merge(
        state:               state_options,
        review:              review_options,
        updated_at_asc:      updated_at_asc_options,
        updated_at_desc:     updated_at_desc_options,
        follow_up_date_asc:  follow_up_date_asc_options,
        follow_up_date_desc: follow_up_date_desc_options
      )
    end

    private

      def risk_asc_options
        risk_options
      end

      def risk_desc_options
        risk_options order: 'DESC'
      end

      def risk_options order: 'ASC'
        name = if HIDE_WEAKNESSES_PRIORITY
                 "#{human_attribute_name :risk}#{order_label order}"
               else
                 "#{human_attribute_name :risk} - #{human_attribute_name :priority}#{order_label order}"
               end

        {
          name:  name,
          field: [
            "#{quoted_table_name}.#{qcn('risk')} #{order}",
            "#{quoted_table_name}.#{qcn('priority')} #{order}",
            "#{quoted_table_name}.#{qcn('state')} ASC"
          ]
        }
      end

      def priority_asc_options
        priority_options
      end

      def priority_desc_options
        priority_options order: 'DESC'
      end

      def priority_options order: 'ASC'
        {
          name:  "#{human_attribute_name :priority} - #{human_attribute_name :risk}#{order_label order}",
          field: [
            "#{quoted_table_name}.#{qcn('priority')} #{order}",
            "#{quoted_table_name}.#{qcn('risk')} #{order}",
            "#{quoted_table_name}.#{qcn('state')} ASC"
          ]
        }
      end

      def state_options
        options_for_attribute :state, order: false
      end

      def review_options
        {
          name: Review.model_name.human,
          field: "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC"
        }
      end

      def updated_at_asc_options
        options_for_attribute :updated_at
      end

      def updated_at_desc_options
        options_for_attribute :updated_at, order: 'DESC'
      end

      def follow_up_date_asc_options
        options_for_attribute :follow_up_date
      end

      def follow_up_date_desc_options
        options_for_attribute :follow_up_date, order: 'DESC'
      end

      def options_for_attribute attribute, order: 'ASC'
        {
          name:  "#{human_attribute_name attribute}#{order_label order}",
          field: "#{quoted_table_name}.#{qcn(attribute)} #{order || 'ASC'}"
        }
      end

      def order_label order
        order_label = { 'ASC' => 'ascendant', 'DESC' => 'descendant' }[order]

        " (#{I18n.t "label.#{order_label}"})" if order
      end
  end
end
