module UsersHelper
  def show_user_with_email_as_acronym(user)
    content_tag(:acronym, h(user.user), :title => user.email)
  end

  def user_resource_field(form, inline = true)
    resource_classes = ResourceClass.human_resources
    
    form.grouped_collection_select(:resource_id, resource_classes, :resources,
      :to_s, :id, :to_s,
      {:prompt => true},
      {:class => (:inline_item if inline)})
  end

  def user_language_field(form, inline = true)
    options = AVAILABLE_LOCALES.map { |lang| [t("lang.#{lang}"), lang.to_s] }

    form.select :language, options.sort{ |a, b| a[0] <=> b[0] }, {},
      {:class => (:inline_item if inline)}
  end

  def user_organizations_field(form, id = nil )
    group = @auth_organization ? @auth_organization.group :
      Group.find_by_admin_hash(params[:hash])
    
    form.select :organization_id, sorted_options_array_for(
      Organization.list_for_group(group), :name, :id), {:prompt => true},
      {:id => "#{id}_organization_id"}
  end
end