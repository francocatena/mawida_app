class AttachedReportJob < ApplicationJob
  queue_as :default

  def perform args
    model           = args.fetch(:model_name).constantize
    ids             = args.fetch :ids
    query_methods   = args.fetch :query_methods, {}.to_json
    filename        = args.fetch :filename
    method_name     = args.fetch :method_name
    options         = args.fetch :options, {}
    user_id         = args.fetch :user_id
    organization_id = args.fetch :organization_id

    query_methods = JSON.parse(query_methods).deep_symbolize_keys

    scope = model.where *build_conditions_for(model, ids)

    query_methods.each do |method, args|
      if args.present?
        arguments = args.is_a?(String) ? args : deep_convert_to_sym(args)
        scope     = scope.send method, arguments
      end
    end

    report   = scope.send method_name, options
    zip_file = zip_report_with_filename report, filename

    extension = File.extname filename
    new_filename = filename.sub(
      /#{Regexp.escape extension}$/,
      '.zip'
    )

    ReportMailer.attached_report(
      filename:        new_filename,
      file:            zip_file,
      user_id:         user_id,
      organization_id: organization_id
    ).deliver_later
  end

  private

    def build_conditions_for model, ids
      conditions = []
      parameters = {}

      ids.uniq.each_slice(500).each_with_index do |id_slice, i|
        parameters[:"ids_#{i}"] = id_slice

        conditions << "#{model.quoted_table_name}.id IN (:ids_#{i})"
      end

      [
        conditions.map { |c| "(#{c})" }.join(' OR '),
        parameters
      ]
    end

    def zip_report_with_filename report, filename
      tmp_file = Dir::Tmpname.create(filename) {}

      Zip::File.open(tmp_file, Zip::File::CREATE) do |zip|
        zip.get_output_stream(filename) { |f| f.write report }
      end

      tmp_file
    end

    def deep_convert_to_sym data
      case data
      when Hash
        data.map { |k, v| [k, deep_convert_to_sym(v)] }.to_h
      when Array
        data.map { |e| e.try(:to_sym) || deep_convert_to_sym(e) }
      when String
        data.to_sym
      else
        data
      end
    end
end
