class LdapMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def import_notifier(imported_users, organization)
    @users = {
      created:   [],
      updated:   [],
      deleted:   []
    }

    imported_users.each do |d|
      @users[d[:state]] << d[:user] unless d[:state] == :unchanged # unused
    end

    emails = organization.users_with_roles(:supervisor, :manager).pluck(:email)
    subject = I18n.t(
      'ldap_mailer.import_notifier.subject',
      organization: organization.prefix.upcase
    )

    mail to: emails, subject: subject
  end
end
