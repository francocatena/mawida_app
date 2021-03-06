class FindingUserAssignment < ApplicationRecord
  include Auditable
  include Comparable
  include FindingUserAssignments::AttributeTypes

  # Scopes
  scope :owners, -> { where(:process_owner => true) }
  scope :responsibles, -> { where(:responsible_auditor => true) }

  # Callbacks
  before_save :can_be_modified?, :assign_finding_type, :users_notification

  # Restricciones
  validates :user_id, :presence => true
  validates :user_id, :numericality => {:only_integer => true},
    :allow_blank => true, :allow_nil => true
  validates_each :process_owner do |record, attr, value|
    organization_id = record.finding.try(:organization_id)

    if value && !record.user&.can_act_as_audited? && !record.user&.can_act_as_audited_on?(organization_id)
      record.errors.add attr, :invalid
    end
  end
  validates_each :user_id do |record, attr, value|
    users = (record.finding || record.raw_finding).finding_user_assignments.
      reject(&:marked_for_destruction?).map(&:user_id)

    record.errors.add attr, :taken if users.select { |u| u == value }.size > 1
  end
  validate :process_owner_uniqueness, if: :validate_process_owner_uniqueness?

  # Relaciones
  belongs_to :finding, :inverse_of => :finding_user_assignments,
    :polymorphic => true, :touch => true, :optional => true
  belongs_to :raw_finding, :foreign_key => :finding_id, :class_name => 'Finding', :optional => true
  belongs_to :user

  def <=>(other)
    if other.kind_of?(FindingUserAssignment) && self.finding_id == other.finding_id
      self.user_id <=> other.user_id
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(FindingUserAssignment) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end

  def can_be_modified?
    (self.finding || self.raw_finding).can_be_modified?
  end

  def assign_finding_type
    self.finding_type = self.finding.try(:type) || self.raw_finding.try(:type)
  end

  def users_notification
    if user_id_changed? && persisted? && !finding.incomplete?
      user_removed = User.find user_id_was

      NotifierMailer.reassigned_findings_notification(
        user, user_removed, finding, false
      ).deliver_later
    end
  end

  private

    def validate_process_owner_uniqueness?
      finding && SHOW_WEAKNESS_EXTRA_ATTRIBUTES
    end

    def process_owner_uniqueness
      process_owners = finding.finding_user_assignments.
        reject(&:marked_for_destruction?).
        select(&:process_owner)

      if process_owners.size > 1 && process_owner
        errors.add :process_owner, :taken
      end
    end
end
