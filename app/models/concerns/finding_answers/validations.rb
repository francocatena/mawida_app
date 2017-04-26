module FindingAnswers::Validations
  extend ActiveSupport::Concern

  included do
    validates :finding_id, :answer, presence: true
    validates :answer, :auditor_comments, pdf_encoding: true
    validates :commitment_date, timeliness: { type: :date }, allow_blank: true
    validates :commitment_date, presence: true, if: :commitment_date_should_be_present?
  end

  private

    def commitment_date_should_be_present?
      current_organization = Organization.current_id &&
        Organization.find(Organization.current_id)

      user&.can_act_as_audited? &&
        finding&.pending? &&
        finding.commitment_date.blank? &&
        current_organization &&
        !current_organization.corporate?
    end
end