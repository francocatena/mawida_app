module TagsHelper
  def tag_kinds
    {
      finding:   Finding.model_name.human(count: 0),
      plan_item: PlanItem.model_name.human(count: 0),
      review:    Review.model_name.human(count: 0),
      document:  Document.model_name.human(count: 0)
    }
  end

  def styles
    styles = %w(default primary success info warning danger)

    styles.map { |k| [t("tags.styles.#{k}"), k] }
  end

  def tags tags
    ActiveSupport::SafeBuffer.new.tap do |buffer|
      tags.each do |tag|
        buffer << content_tag(:span, class: "text-#{tag.style}") do
          content_tag :span, nil, class: 'glyphicon glyphicon-tag', title: tag.name
        end
      end
    end
  end
end
