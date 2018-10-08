module Reports::FileResponder

  def render_or_send_by_mail args
    collection  = args.fetch :collection
    filename    = args.fetch :filename
    method_name = args.fetch :method_name
    options     = args.fetch :options, {}

    if send_report_by_email? collection
      perform_report_and_redirect_back args
    else
      render request.format.symbol => collection.send(method_name, options), filename: filename
    end
  end

  private

    def send_report_by_email? collection
      collection.unscope(:group).count > SEND_REPORT_EMAIL_AFTER_COUNT
    end

    def perform_report_and_redirect_back args
      collection  = args.fetch :collection
      filename    = [args.fetch(:filename), request.format.symbol].join '.'
      method_name = args.fetch(:method_name).to_s
      options     = args.fetch :options, {}

      AttachedReportJob.perform_later(
        model_name:      collection.model_name.name,
        ids:             collection.ids,
        query_methods:   report_query_methods(collection),
        user_id:         Current.user.id,
        organization_id: Current.organization.id,
        filename:        filename,
        method_name:     method_name,
        options:         options
      )

      parameters = request.query_parameters.except 'format'

      back_url = if parameters.present?
                   [request.path, parameters.to_param].join '?'
                 else
                   request.path
                 end

      redirect_to back_url, notice: t('reports.file_will_be_sent')
    end

    def report_query_methods collection
      {
        joins:            collection.joins_values,
        left_outer_joins: collection.left_outer_joins_values,
        includes:         collection.includes_values,
        group:            collection.group_values,
        reorder:          collection.order_values.map(&:to_s).join(', '),
        references:       collection.references_values
      }.to_json
    end
end
