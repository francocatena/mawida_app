module ConclusionReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :review_id, :organization_id, :issue_date, presence: true
    validates :applied_procedures, presence: true, unless: :validate_extra_attributes?
    validates :conclusion, :applied_procedures, :summary, :recipients, :sectors,
      pdf_encoding: true
    validates :type, :summary, :evolution, length: { maximum: 255 }
    validates :issue_date, timeliness: { type: :date }, allow_nil: true

    validates :recipients, :sectors, :evolution, :evolution_justification,
      presence: true, if: :validate_extra_attributes?
    validates :main_weaknesses_text, :corrective_actions, presence: true,
      if: :validate_short_alternative_pdf_attributes?
  end

  private

    def validate_extra_attributes?
      SHOW_CONCLUSION_ALTERNATIVE_PDF
    end

    def validate_short_alternative_pdf_attributes?
      organization = Organization.find Organization.current_id

      ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include? organization.prefix
    end
end
