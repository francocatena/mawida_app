class ErrorRecordPdf < Prawn::Document

  def initialize from: nil, to: nil, error_records: nil,
    current_organization: nil

    @current_organization = current_organization
    @from, @to, @error_records = from, to, error_records

    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def generate
    add_header
    add_description
    add_body
    save
  end

  def relative_path
    Prawn::Document.relative_path(pdf_name, ErrorRecord.table_name)
  end

  private

    def add_header
      @pdf.add_generic_report_header @current_organization
      @pdf.add_title I18n.t('error_record.index_title')
    end

    def add_description
      @pdf.move_down PDF_FONT_SIZE

      @pdf.add_description_item(
        I18n.t('error_record.period.title'),
        I18n.t('error_record.period.range',
          from_date: I18n.l(@from, format: :long),
          to_date: I18n.l(@to, format: :long))
      )
    end

    def add_body
      column_data = make_column_data

      if column_data.present?
        @pdf.move_down PDF_FONT_SIZE
        @pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = @pdf.default_table_options(column_widths)

          @pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              background_color: 'cccccc',
              padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end
    end

    def make_column_data
      @error_records.map do |error_record|
        user_name = error_record.user.try(:user) || I18n.t('error_record.void_user')
        [
          "<b>#{user_name}</b>",
          error_record.created_at ? I18n.l(error_record.created_at, format: :minimal) : '-',
          error_record.error_text, error_record.data
        ]
      end
    end

    def column_order
      { 'user_id' => 20, 'created_at' => 15, 'error' => 15, 'data' => 50 }
    end

    def column_headers
      column_order.keys.map { |col_name| ErrorRecord.human_attribute_name(col_name) }
    end

    def column_widths
      column_order.values.map { |col_with| @pdf.percent_width(col_with) }
    end

    def save
      @pdf.custom_save_as(pdf_name, ErrorRecord.table_name)
    end

    def pdf_name
      I18n.t 'error_record.pdf_list_name',
        from_date: @from.to_s(:db), to_date: @to.to_s(:db)
    end
end
