module Reviews::FindingCode
  extend ActiveSupport::Concern

  def recode_weaknesses
    recode_findings weaknesses
  end

  def recode_oportunities
    recode_findings oportunities
  end

  def recode_weaknesses_by_risk
    recode_findings weaknesses, order: [risk: :desc, review_code: :asc]
  end

  def recode_weaknesses_by_control_objective_order
    order      = [risk: :desc, review_code: :asc]
    weaknesses = []
    revoked    = []

    grouped_control_objective_items.each do |_pc, cois|
      cois.sort.each do |coi|
        weaknesses += coi.weaknesses.not_revoked.order(order).to_a
        revoked    += coi.weaknesses.revoked.to_a
      end
    end

    assign_new_review_code_to_findings weaknesses, revoked
  end

  def next_weakness_code prefix = nil
    next_finding_code prefix, weaknesses.with_prefix(prefix)
  end

  def next_oportunity_code prefix = nil
    next_finding_code prefix, oportunities.with_prefix(prefix)
  end

  private

    def revoked_prefix
      I18n.t 'code_prefixes.revoked'
    end

    def next_finding_code prefix, findings
      last_review_code = findings.order(:review_code).last&.review_code || '0'
      last_number      = last_review_code.match(/\d+\Z/).to_a.first.to_i

      raise 'A review can not have more than 999 findings' if last_number > 999

      "#{prefix}#{'%.3d' % last_number.next}".strip
    end

    def recode_findings findings, order: :review_code
      raise 'Cannot recode if final review' if has_final_review?

      findings = findings.order order

      assign_new_review_code_to_findings findings.not_revoked, findings.revoked
    end

    def assign_new_review_code_to_findings not_revoked, revoked
      self.class.transaction do
        revoked.each_with_index do |f, i|
          unless f.review_code.start_with? revoked_prefix
            f.update_column :review_code, "#{revoked_prefix}#{f.review_code}"
          end
        end

        not_revoked.each_with_index do |f, i|
          new_code = "#{f.prefix}#{'%.3d' % i.next}"

          f.update_column :review_code, new_code
        end
      end
    end
end
