module OrganizationsHelper
  def organization_image_tag thumb_name = :thumb
    scoped_organization_image thumb_name if image_persisted?
  end

  def organization_image
    @organization.build_image_model unless @organization.image_model

    @organization.image_model
  end

  def organization_kinds
    collection = ORGANIZATION_KINDS.map do |kind|
      [t("activerecord.attributes.organization.kind_options.#{kind}"), kind]
    end
  end

  private

    def image_persisted?
      @organization.image_model && !@organization.image_model.image_cache
    end

    def scoped_organization_image thumb_name
      Fiber.new do
        Organization.current_id = @organization.id

        image_tag @organization.image_model.image.url(thumb_name),
          size: @organization.image_model.image_size(thumb_name)
      end.resume
    end
end
