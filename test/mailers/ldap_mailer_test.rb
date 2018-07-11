require 'test_helper'

class NotifierMailerTest < ActionMailer::TestCase
  fixtures :users, :organizations, :groups, :organization_roles, :roles,
    :ldap_configs

  setup do
    ActionMailer::Base.deliveries.clear

    assert_empty ActionMailer::Base.deliveries
  end

  teardown do
    Organization.current_id = nil
  end

  test 'Notify with imported users' do
    org = organizations(:google)
    Organization.current_id = org.id

    ldap_config = ldap_configs(:google_ldap)
    imports = ldap_config.import('admin', 'admin123')

    filtered_imports = imports.map do |i|
      unless i[:state] == :unchanged
        { user: { name: i[:user].to_s, errors: i[:errors] }, state: i[:state] }
      end
    end.compact

    response = LdapMailer.import_notifier(filtered_imports.to_json, org.id).deliver_now

    assert_not_empty ActionMailer::Base.deliveries
    assert_includes response.to, users(:supervisor).email
  end
end
