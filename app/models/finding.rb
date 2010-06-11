class Finding < ActiveRecord::Base
  include Comparable
  include ParameterSelector

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :review => {
      :column => "LOWER(#{Review.table_name}.identification)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.table_name}.project)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :review_code => {
      :column => "LOWER(#{table_name}.review_code)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :description => {
      :column => "LOWER(#{table_name}.description)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  acts_as_tree
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  STATUS = {
    :confirmed => -3,
    :unconfirmed => -2,
    :unanswered => -1,
    :being_implemented => 0,
    :implemented => 1,
    :implemented_audited => 2,
    :assumed_risk => 3,
    :notify => 4,
    :incomplete => 5
  }.freeze

  STATUS_TRANSITIONS = {
    :confirmed => [
      :confirmed,
      :unanswered,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :unconfirmed => [
      :unconfirmed,
      :confirmed,
      :unanswered
    ],
    :unanswered => [
      :unanswered,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :being_implemented => [
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :implemented => [
      :implemented,
      :being_implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :implemented_audited => [
      :implemented_audited
    ],
    :assumed_risk => [
      :assumed_risk
    ],
    :notify => [
      :notify,
      :incomplete,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ],
    :incomplete => [
      :incomplete,
      :notify,
      :being_implemented,
      :implemented,
      :implemented_audited,
      :assumed_risk
    ]
  }

  PENDING_STATUS = [
    STATUS[:being_implemented], STATUS[:notify], STATUS[:implemented],
    STATUS[:unconfirmed], STATUS[:confirmed], STATUS[:unanswered],
    STATUS[:incomplete]
  ]

  EXCLUDE_FROM_REPORTS_STATUS = [:unconfirmed, :confirmed, :notify, :incomplete]

  # Atributos no persistente
  attr_accessor :users_for_notification, :user_who_make_it

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:user_ids, :workpaper_ids]

  # Named scopes
  named_scope :with_prefix, lambda { |prefix|
    {
      :conditions => ['review_code LIKE ?', "#{prefix}%"],
      :order => 'review_code ASC'
    }
  }
  named_scope :all_for_reallocation_with_review, lambda { |review|
    {
      :include => {:control_objective_item => :review},
      :conditions => {:reviews => {:id => review.id}, :state => PENDING_STATUS}
    }
  }
  named_scope :all_for_reallocation, :conditions => {:state => PENDING_STATUS}
  named_scope :for_notification, :conditions => {:state => STATUS[:notify],
    :final => false}
  named_scope :finals, lambda { |use_finals|
    { :conditions => { :final => use_finals } }
  }
  named_scope :sort_by_code, :order => 'review_code ASC'
  named_scope :next_to_expire, :conditions => [
    [
      'follow_up_date = :warning_date',
      'state = :being_implemented_state'
    ].join(' AND '),
    {
      :warning_date =>
        FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date,
      :being_implemented_state => STATUS[:being_implemented]
    }
  ]
  named_scope :unconfirmed_for_notification, :conditions => [
    [
      'first_notification_date >= :stale_unconfirmed_date',
      'state = :state',
      'final = :boolean_false'
    ].join(' AND '),
    {
      :state => STATUS[:unconfirmed],
      :boolean_false => false,
      :stale_unconfirmed_date =>
        FINDING_STALE_UNCONFIRMED_DAYS.days.ago_in_business.to_date
    }
  ]
  named_scope :unconfirmed_and_stale, :conditions => [
    [
      'first_notification_date < :stale_unconfirmed_date',
      'state = :state',
      'final = :boolean_false'
    ].join(' AND '),
    {
      :state => STATUS[:unconfirmed],
      :boolean_false => false,
      :stale_unconfirmed_date => (FINDING_STALE_UNCONFIRMED_DAYS +
          FINDING_STALE_CONFIRMED_DAYS).days.ago_in_business.to_date
    }
  ]
  named_scope :confirmed_and_stale,
    :include => :finding_answers,
    :conditions => [
      [
        [
          'confirmation_date < :stale_confirmed_date',
          'state = :state',
          'final = :boolean_false'
        ].join(' AND '),
        [
          'first_notification_date < :stale_first_notification_date',
          'state = :state',
          'final = :boolean_false'
        ].join(' AND '),
      ].map {|c| "(#{c})"}.join(' OR '),
      {
        :state => STATUS[:confirmed],
        :boolean_false => false,
        :stale_confirmed_date =>
          FINDING_STALE_CONFIRMED_DAYS.days.ago_in_business.to_date,
        :stale_first_notification_date => (FINDING_STALE_UNCONFIRMED_DAYS +
            FINDING_STALE_CONFIRMED_DAYS).days.ago_in_business.to_date
      }
    ]
  named_scope :being_implemented, :conditions =>
    {:state => STATUS[:being_implemented]}
  named_scope :list_all_by_date, lambda { |from_date, to_date|
    {
      :include => {
        :control_objective_item => {:review =>
            [:period, :conclusion_final_review, {:plan_item => :business_unit}]}
      },
      :conditions => [
        [
          "#{ConclusionReview.table_name}.issue_date BETWEEN :begin AND :end",
          "#{Period.table_name}.organization_id = :organization_id",
          'state IN (:states)'
        ].join(' AND '),
        {
          :begin => from_date, :end => to_date,
          :organization_id => GlobalModelConfig.current_organization_id,
          :states => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values
        }
      ]
    }
  }
  named_scope :list_all_in_execution_by_date, lambda { |from_date, to_date|
    {
      :include => {
        :control_objective_item =>
          {:review => [:period, :conclusion_final_review]}
      },
      :conditions => [
        [
          "#{Review.table_name}.created_at BETWEEN :begin AND :end",
          "#{Period.table_name}.organization_id = :organization_id",
          "#{ConclusionFinalReview.table_name}.review_id IS NULL"
        ].join(' AND '),
        {
          :begin => from_date, :end => to_date,
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ]
    }
  }
  named_scope :internal_audit,
    :include => {
      :control_objective_item => {:review => {:plan_item => :business_unit}}
    },
    :conditions => [
      "#{BusinessUnit.table_name}.business_unit_type IN (:types)",
      {:types => BusinessUnit::INTERNAL_TYPES.values}
    ]
  named_scope :external_audit,
    :include => {
      :control_objective_item => {:review => {:plan_item => :business_unit}}
    },
    :conditions => {
      "#{BusinessUnit.table_name}.business_unit_type" =>
        BusinessUnit::TYPES[:external_audit]
    }
  named_scope :bcra_audit,
    :include => {
      :control_objective_item => {:review => {:plan_item => :business_unit}}
    },
    :conditions => {
      "#{BusinessUnit.table_name}.business_unit_type" =>
        BusinessUnit::TYPES[:bcra]
    }

  # Restricciones sobre los atributos
  attr_protected :first_notification_date, :final
  attr_accessor :nested_user, :finding_prefix, :avoid_changes_notification
  attr_readonly :review_code

  # Callbacks
  before_create :can_be_created?
  before_save :can_be_modified?, :check_users_for_notification
  before_destroy :can_be_destroyed?
  after_update :notify_changes_to_users

  # Restricciones
  validates_presence_of :control_objective_item_id, :description, :review_code
  validates_length_of :review_code, :type, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_numericality_of :control_objective_item_id, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validates_date :first_notification_date, :allow_nil => true
  validates_date :follow_up_date, :allow_nil => true, :allow_blank => true
  validates_date :solution_date, :allow_nil => true, :allow_blank => true
  validates_each :follow_up_date do |record, attr, value|
    check_for_blank = record.kind_of?(Weakness) && (record.being_implemented? ||
        record.implemented? || record.implemented_audited?)

    record.errors.add attr, :blank if check_for_blank && value.blank?
    record.errors.add attr, :must_be_blank if !check_for_blank && !value.blank?
  end
  validates_each :solution_date do |record, attr, value|
    check_for_blank = record.implemented_audited? || record.assumed_risk?

    record.errors.add attr, :blank if check_for_blank && value.blank?
    record.errors.add attr, :must_be_blank if !check_for_blank && !value.blank?
  end
  validates_each :answer do |record, attr, value|
    check_for_blank = record.being_implemented? ||
      (record.state_changed? && record.state_was == STATUS[:confirmed])

    record.errors.add attr, :blank if check_for_blank && value.blank?
  end
  validates_each :state do |record, attr, value|
    if value && record.state_changed? &&
        !record.next_status_list(record.state_was).values.include?(value)
      record.errors.add attr, :inclusion
    end

    record.errors.add attr, :must_have_a_comment if record.must_have_a_comment?
    
    if record.implemented_audited? && record.work_papers.empty?
      record.errors.add attr, :must_have_a_work_paper
    end
  end
  validates_each :review_code do |record, attr, value|
    review = record.control_objective_item.try(:review)

    if review
      (review.weaknesses | review.oportunities).each do |finding|
        another_record = (!record.new_record? && finding.id != record.id) ||
          (record.new_record? && finding.object_id != record.object_id)

        if value == finding.review_code && another_record &&
            (record.final == finding.final)
          record.errors.add attr, :taken
        end
      end
    end
  end
  validates_each :users do |record, attr, value|
    unless value.any?(&:can_act_as_audited?) && value.any?(&:auditor?) &&
        value.any?(&:supervisor?) && value.any?(&:manager?)
      record.errors.add attr, :invalid
    end
  end

  # Relaciones
  belongs_to :control_objective_item
  has_one :review, :through => :control_objective_item
  has_one :control_objective, :through => :control_objective_item,
    :class_name => 'ControlObjective'
  has_many :finding_answers, :dependent => :destroy,
    :after_add => :answer_added, :order => 'created_at ASC'
  has_many :notification_relations, :as => :model, :dependent => :destroy
  has_many :notifications, :through => :notification_relations, :uniq => true,
    :order => 'created_at'
  has_many :costs, :as => :item, :dependent => :destroy
  # TODO: cambiar la linea de abajo por la comentada cuando termine el proceso de "papelización"
  has_many :work_papers, :as => :owner, :dependent => :destroy,
    :before_add => :prepare_work_paper,
    :before_remove => :check_for_final_review, :order => 'created_at ASC'
#  has_many :work_papers, :as => :owner, :dependent => :destroy,
#    :before_add => [:check_for_final_review, :prepare_work_paper],
#    :before_remove => :check_for_final_review, :order => 'created_at ASC'
  has_many :comments, :as => :commentable, :dependent => :destroy,
    :order => 'created_at ASC'
  has_and_belongs_to_many :users, :validate => false,
    :order => 'last_name ASC, name ASC', :after_add => :user_changed,
    :after_remove => :user_changed
  
  accepts_nested_attributes_for :finding_answers, :allow_destroy => false
  accepts_nested_attributes_for :work_papers, :allow_destroy => true
  accepts_nested_attributes_for :costs, :allow_destroy => false
  accepts_nested_attributes_for :comments, :allow_destroy => false

  def initialize(attributes = nil, import_users = false)
    super(attributes)

    if import_users && self.control_objective_item.try(:review)
      self.user_ids |= self.control_objective_item.review.user_ids
    end

    unless self.control_objective_item.try(:controls).blank?
      self.effect ||= self.control_objective_item.controls.first.try(:effects)
    end

    self.state ||= STATUS[:incomplete]
    self.final ||= false
    self.finding_prefix ||= false
  end

  def <=>(other)
    other.kind_of?(Finding) ? self.id <=> other.id : -1
  end

  def check_for_final_review(_)
    if self.final? && self.review && self.review.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def organization
    self.review.try(:organization)
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix ||= self.get_parameter(
      :admin_code_prefix_for_work_papers_in_weaknesses_follow_up)
    work_paper.neighbours ||= 
      (self.control_objective_item.try(:review).try(:work_papers) || []) +
      self.work_papers.reject { |wp| wp == work_paper }
  end

  def answer_added(finding_answer)
    if (self.unconfirmed? || self.notify?) &&
        finding_answer.user.try(:can_act_as_audited?)
      self.confirmed! finding_answer.user
    end
  end
  
  def user_changed(user)
    @users_change = true
    @users_added ||= []
    @users_removed ||= []

    if self.users.include?(user)
      @users_added << user
    else
      @users_removed << user
    end
  end

  def notify_changes_to_users
    unless self.avoid_changes_notification
      if @users_change && !@users_added.blank? && !@users_removed.blank?
        Notifier.deliver_reassigned_findings_notification(@users_added,
          @users_removed, self, false)
      elsif @users_change && @users_added.blank? && !@users_removed.blank?
        title = I18n.t(:'finding.responsibility_removed',
          :class_name => self.class.human_name.downcase,
          :review_code => self.review_code,
          :review => self.review.try(:identification))

        Notifier.deliver_changes_notification @users_removed, :title => title
      end
    end
  end

  def can_be_modified?(include_error_messages = true)
    # TODO: Eliminar las dos líneas inferiores cuando termine el proceso de "papelización"
    if self.implemented_audited? && !self.changed? &&
        self.work_papers.reject(&:new_record?).empty?
      true
    elsif !self.final? || self.final_changed? ||
        (!self.changed? && !self.control_objective_item.review.is_frozen?)
      true
    else
      msg = I18n.t(:'finding.readonly')

      # TODO: Eliminar el parámetro "include_error_messages" cuando termine el proceso de "papelización"
      if !self.errors.full_messages.include?(msg) && include_error_messages
        self.errors.add_to_base msg
      end

      false
    end
  end

  def can_be_created?
    unless self.is_in_a_final_review? &&
        (self.changed? || self.marked_for_destruction?)
      true
    else
      msg = I18n.t(:'finding.readonly')
      self.errors.add_to_base msg unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def can_be_destroyed?
    self.is_in_a_final_review? ? false : true
  end

  def is_in_a_final_review?
    self.control_objective_item && self.control_objective_item.review &&
      self.control_objective_item.review.has_final_review?
  end

  def check_users_for_notification
    unless (self.users_for_notification || []).reject(&:blank?).blank?
      self.users_for_notification.reject(&:blank?).each do |user_id|
        Notifier.deliver_notify_new_finding self.users.find(user_id), self
      end
    end
  end

  def must_have_a_comment?
    self.being_implemented? && self.was_implemented? &&
      !self.comments.detect { |c| c.new_record? && c.valid? }
  end

  def mark_as_unconfirmed!
    self.first_notification_date = Date.today unless self.unconfirmed?
    self.state = STATUS[:unconfirmed] if self.notify?
    
    self.save false
  end

  def confirmed!(user = nil)
    if self.unconfirmed? || self.notify?
      self.update_attribute :state, STATUS[:confirmed]

      if self.confirmation_date.blank?
        self.update_attribute :confirmation_date, Date.today
      end

      if user
        self.notifications.not_confirmed.each do |notification|
          if notification.user.audited?
            notification.update_attributes!(
              :status => Notification::STATUS[:confirmed],
              :confirmation_date => notification.confirmation_date || Time.now,
              :user_who_confirm => user
            )
          end
        end
      end
    end
  end

  STATUS.each do |status_type, status_value|
    define_method("#{status_type}?") { self.state == status_value }
  end

  STATUS.each do |status_type, status_value|
    define_method("was_#{status_type}?") { self.state_was == status_value }
  end

  def state_text
    self.state ? I18n.t("finding.status_#{STATUS.invert[self.state]}") : '-'
  end
  
  def stale?
    self.being_implemented? && self.follow_up_date &&
      self.follow_up_date < Time.now.to_date
  end

  def pending?
    PENDING_STATUS.include?(self.state)
  end

  def has_audited?
    self.users.any? { |user| user.can_act_as_audited? }
  end

  def has_auditor?
    self.users.any? { |user| user.auditor? }
  end

  def cost
    self.costs.reject { |c| c.new_record? }.sum(&:cost)
  end

  def issue_date
    self.review.try(:conclusion_final_review).try(:issue_date)
  end

  def important_dates
    important_dates = []

    unless self.notifications.empty?
      important_dates << I18n.t(:'finding.important_dates.notification_date',
        :date => I18n.l(self.notifications.first.created_at,
          :format => :very_long).strip)
    end

    if self.confirmed? && self.confirmation_date
      notification_or_answer = self.notifications.detect {|n| n.user.audited?} ||
        self.finding_answers.detect {|fa| fa.user.audited?}
      date = (notification_or_answer.respond_to?(:confirmation_date) ?
        notification_or_answer.confirmation_date : nil) ||
        notification_or_answer.created_at

      if date
        important_dates << I18n.t(:'finding.important_dates.confirmation_date',
          :date => I18n.l(date, :format => :very_long).strip)
      end
    end

    if self.confirmed? || self.unconfirmed? ||
        Finding.confirmed_and_stale.exists?(self.id)

      if self.confirmation_date
        max_notification_date = FINDING_STALE_CONFIRMED_DAYS.days.
          ago_in_business.to_date
        expiration_diff = self.confirmation_date.try(:diff_in_business,
          max_notification_date)
      else
        max_notification_date = (FINDING_STALE_UNCONFIRMED_DAYS +
            FINDING_STALE_CONFIRMED_DAYS).days.ago_in_business.to_date
        expiration_diff = self.first_notification_date.try(:diff_in_business,
          max_notification_date)
      end

      if expiration_diff && expiration_diff >= 0
        important_dates << I18n.t(:'finding.important_dates.expiration_date',
          :date => I18n.l(expiration_diff.days.from_now_in_business.to_date,
            :format => :long).strip)
      end
    end

    important_dates
  end

  def next_status_list(state = nil)
    state_key = STATUS.invert[state || self.state]
    allowed_keys = STATUS_TRANSITIONS[state_key]

    STATUS.reject {|k,| !allowed_keys.include?(k)}
  end
  
  def versions_between(start_date = nil, end_date = nil)
    conditions = []
    conditions << 'created_at >= :filter_start' if start_date
    conditions << 'created_at <= :filter_end' if end_date
    conditions.blank? ? self.versions : self.versions.all(
      :conditions => [conditions.join(' AND '),
        {:filter_start => start_date, :filter_end => end_date}])
  end

  def versions_after_final_review(end_date = nil)
    self.versions_between(self.control_objective_item.try(:review).try(
        :conclusion_final_review).try(:created_at), end_date)
  end

  def versions_before_final_review(start_date = nil)
    self.versions_between(start_date, self.control_objective_item.try(
        :review).try(:conclusion_final_review).try(:created_at))
  end

  def status_change_history
    last_version = self.versions.last
    self.user_who_make_it = last_version.try(:whodunnit) ?
      User.find(last_version.whodunnit) : nil
    findings_with_status_changed = [self]
    last_added_version = self

    self.versions_after_final_review.reverse.each do |version|
      old_finding = version.reify

      if old_finding && old_finding.state != last_added_version.state
        last_added_version = old_finding

        if version.previous.try(:whodunnit)
          old_finding.user_who_make_it = User.find(version.previous.whodunnit)
        end
        
        findings_with_status_changed << old_finding
      elsif old_finding
        findings_with_status_changed[-1] = old_finding
      end
    end

    findings_with_status_changed.sort {|f1, f2| f1.updated_at <=> f2.updated_at}
  end

  def to_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)

    pdf.add_review_header organization, self.review.identification.strip,
      self.review.plan_item.project.strip

    pdf.move_pointer 36

    pdf.add_title self.class.human_name, 18, :center, false

    pdf.move_pointer 12

    pdf.add_title "<b>#{self.class.human_attribute_name('review_code')}</b>: " +
      self.review_code, 12, :center, false

    pdf.start_new_page

    pdf.move_pointer 28

    pdf.add_description_item(
      self.class.human_attribute_name('control_objective_item_id'),
      self.control_objective_item.control_objective_text, 0, false)
    pdf.add_description_item(self.class.human_attribute_name('review_code'),
      self.review_code, 0, false)
    pdf.add_description_item(self.class.human_attribute_name('description'),
      self.description, 0, false)

    pdf.move_pointer 28

    if self.kind_of?(Weakness)
      pdf.add_description_item(Weakness.human_attribute_name('risk'),
        self.risk_text, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name('priority'),
        self.priority_text, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name('effect'),
        self.effect, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(
          'audit_recommendations'), self.audit_recommendations, 0, false)
    end

    pdf.add_description_item(self.class.human_attribute_name('answer'),
      self.answer, 0, false) unless self.unanswered?

    if self.kind_of?(Weakness) && (self.implemented? || self.being_implemented?)
      pdf.add_description_item(Weakness.human_attribute_name('follow_up_date'),
        (I18n.l(self.follow_up_date, :format => :long) if self.follow_up_date),
        0, false)
    end

    if self.implemented_audited?
      pdf.add_description_item(self.class.human_attribute_name('solution_date'),
        (I18n.l(self.solution_date, :format => :long) if self.solution_date), 0,
        false)
    end

    audited = self.users.select { |u| u.can_act_as_audited? }.map(&:full_name)

    pdf.add_description_item(self.class.human_attribute_name('user_ids'),
      audited.join('; '), 0, false)

    pdf.add_description_item(self.class.human_attribute_name('audit_comments'),
      self.audit_comments, 0, false)

    pdf.add_description_item(self.class.human_attribute_name('state'),
      self.state_text, 0, false)

    unless self.work_papers.blank?
      pdf.start_new_page
      pdf.move_pointer 36

      pdf.add_title(ControlObjectiveItem.human_attribute_name('work_papers'),
        18, :center, false)
      pdf.add_title("#{self.class.human_name} #{self.review_code}", 18, :center,
        false)

      pdf.move_pointer 36

      self.work_papers.each do |wp|
        pdf.text wp.inspect, :justification => :center, :font_size => 12
      end
    else
      pdf.add_footnote(I18n.t(:'finding.without_work_papers'))
    end

    pdf.custom_save_as(self.pdf_name, self.class.table_name, self.id)
  end

  def absolute_pdf_path
    PDF::Writer.absolute_path(self.pdf_name, self.class.table_name, self.id)
  end

  def relative_pdf_path
    PDF::Writer.relative_path(self.pdf_name, self.class.table_name, self.id)
  end

  def pdf_name
    ("#{self.class.human_name.downcase.gsub(/\s+/, '_')}-" +
      "#{self.review_code}.pdf").gsub(/[^A-Za-z0-9\.\-]+/, '_')
  end

  def follow_up_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait)
    issue_date = self.issue_date ? I18n.l(self.issue_date, :format => :long) :
      I18n.t(:'finding.without_conclusion_final_review')

    add_finding_follow_up_header pdf, organization
    
    pdf.add_title I18n.t("finding.follow_up_report.#{self.class.name.downcase}"+
        '.title'), 14, :center

    pdf.move_pointer 14

    pdf.add_title I18n.t("finding.follow_up_report.#{self.class.name.downcase}"+
        '.subtitle'), 14, :left

    pdf.move_pointer 14

    pdf.add_description_item(Review.human_name,
      "#{self.review.long_identification} (#{issue_date})", 0, false)
    pdf.add_description_item(PlanItem.human_attribute_name(:project),
      self.review.plan_item.project, 0, false)
    pdf.add_description_item(Finding.human_attribute_name(:review_code),
      self.review_code, 0, false)
    
    pdf.add_description_item(Finding.human_attribute_name(
        :control_objective_item_id),
      self.control_objective_item.control_objective_text, 0, false)
    pdf.add_description_item(self.class.human_attribute_name(:description),
      self.description, 0, false)
    pdf.add_description_item(self.class.human_attribute_name(:state),
      self.state_text, 0, false)

    if self.kind_of?(Weakness)
      pdf.add_description_item(self.class.human_attribute_name(:risk),
        self.risk_text, 0, false)
      pdf.add_description_item(self.class.human_attribute_name(:priority),
        self.priority_text, 0, false)
      pdf.add_description_item(Finding.human_attribute_name(:effect),
        self.effect, 0, false)
      pdf.add_description_item(Finding.human_attribute_name(
          :audit_recommendations), self.audit_recommendations, 0, false)
    end
    
    pdf.add_description_item(Finding.human_attribute_name(:answer),
      self.answer, 0, false)

    if self.kind_of?(Weakness) && self.follow_up_date
      pdf.add_description_item(Finding.human_attribute_name(:follow_up_date),
        I18n.l(self.follow_up_date, :format => :long), 0, false)
    end

    if self.solution_date
      pdf.add_description_item(Finding.human_attribute_name(:solution_date),
        I18n.l(self.solution_date, :format => :long), 0, false)
    end

    audited, auditors = *self.users.partition(&:can_act_as_audited?)

    pdf.add_title I18n.t(:'finding.auditors', :count => auditors.size), 12,
      :left
    pdf.add_list auditors.map(&:full_name), 24

    pdf.add_title I18n.t(:'finding.responsibles', :count => audited.size), 12,
      :left
    pdf.add_list audited.map(&:full_name), 24
    
    important_attributes = [:state, :risk, :priority, :follow_up_date]
    important_changed_versions = []
    previous_version = self.versions.first

    while (previous_version.try(:event) &&
          last_checked_version = (previous_version.try(:next) ||
            Version.new(:object => object_to_string(self))))
      has_important_changes = important_attributes.any? do |attribute|
        current_value = last_checked_version.reify ?
          last_checked_version.reify.send(attribute) : nil
        old_value = previous_version.reify ?
          previous_version.reify.send(attribute) : nil

        if attribute == :follow_up_date
          current_value
          old_value
        end

        current_value != old_value
      end

      important_changed_versions << previous_version if has_important_changes

      previous_version = last_checked_version
    end

    pdf.add_title I18n.t(:'finding.change_history'), 14, :full

    if important_changed_versions.size > 1
      last_checked_version = self.versions.first
      column_names = {'attribute' => 30, 'old_value' => 35, 'new_value' => 35}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_name == 'attribute' ?
            '' : I18n.t("version.column_#{col_name}")
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      previous_version = important_changed_versions.shift
      previous_finding = previous_version.reify

      important_changed_versions.each do |version|
        version_finding = version.reify
        column_data = []

        important_attributes.each do |attribute|
          previous_method_name = previous_finding.respond_to?(
            "#{attribute}_text") ? "#{attribute}_text".to_sym : attribute
          version_method_name = version_finding.respond_to?(
            "#{attribute}_text") ? "#{attribute}_text".to_sym : attribute

          column_data << {
            'attribute' => Finding.human_attribute_name(attribute).to_iso,
            'old_value' => previous_finding.try(:send, previous_method_name).
              to_translated_string.to_iso,
            'new_value' => version_finding.try(:send, version_method_name).
              to_translated_string.to_iso
          }
        end

        unless column_data.blank?
          pdf.move_pointer 12
          
          pdf.add_description_item(Version.human_attribute_name(:created_at),
            I18n.l(previous_version.created_at, :format => :long))
          pdf.add_description_item(User.human_name, previous_version.whodunnit ?
              User.find(previous_version.whodunnit).try(:full_name) : nil)

          pdf.move_pointer 12

          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data
            table.column_order = ['attribute', 'old_value', 'new_value']
            table.split_rows = true
            table.row_gap = 8
            table.font_size = 10
            table.shade_rows = :none
            table.shade_heading_color = Color::RGB::Grey70
            table.heading_font_size = 10
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.show_lines = :all
            table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
            table.render_on pdf
          end
        end

        previous_finding = version_finding
        previous_version = version
      end
    else
      pdf.text(
        "\n#{I18n.t(:'finding.follow_up_report.without_important_changes')}",
        :font_size => 12)
    end

    unless self.work_papers.blank?
      column_names = {'name' => 20, 'code' => 20, 'number_of_pages' => 20,
        'description' => 40}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = WorkPaper.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      self.work_papers.each do |work_paper|
        column_data << {
          'name' => work_paper.name.try(:to_iso),
          'code' => work_paper.code.try(:to_iso),
          'number_of_pages' => work_paper.number_of_pages || '-',
          'description' => work_paper.description.try(:to_iso)
        }
      end

      pdf.move_pointer 12

      pdf.add_title I18n.t(:'finding.follow_up_report.work_papers'), 14, :full

      pdf.move_pointer 12

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['name', 'code', 'number_of_pages',
            'description']
          table.split_rows = true
          table.row_gap = 8
          table.font_size = 10
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB::Grey70
          table.heading_font_size = 10
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    unless self.finding_answers.blank?
      column_names = {'answer' => 50, 'user_id' => 30, 'created_at' => 20}
      columns, column_data = {}, []

      column_names.each do |col_name, col_size|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = FindingAnswer.human_attribute_name col_name
          c.justification = :full
          c.width = pdf.percent_width(col_size)
        end
      end

      self.finding_answers.each do |finding_answer|
        column_data << {
          'answer' => finding_answer.answer.try(:to_iso),
          'user_id' => finding_answer.user.try(:full_name).try(:to_iso),
          'created_at' => I18n.l(finding_answer.created_at,
            :format => :validation).to_iso
        }
      end

      pdf.move_pointer 12
      
      pdf.add_title I18n.t(:'finding.follow_up_report.follow_up_comments'), 14,
        :full
      
      pdf.move_pointer 12

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = ['user_id', 'answer', 'created_at']
          table.split_rows = true
          table.row_gap = 8
          table.font_size = 10
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB::Grey70
          table.heading_font_size = 10
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.inner_line_style = PDF::Writer::StrokeStyle.new(0.5)
          table.render_on pdf
        end
      end
    end

    pdf.custom_save_as self.follow_up_pdf_name, Finding.table_name, self.id
  end

  def absolute_follow_up_pdf_path
    PDF::Writer.absolute_path self.follow_up_pdf_name, Finding.table_name,
      self.id
  end

  def relative_follow_up_pdf_path
    PDF::Writer.relative_path self.follow_up_pdf_name, Finding.table_name,
      self.id
  end

  def follow_up_pdf_name
    code = self.review_code.gsub /[^A-Za-z0-9\.\-]+/, '_'

    I18n.t(:'finding.follow_up_report.pdf_name', :code => code)
  end

  def self.notify_for_unconfirmed_for_notification_findings
    # Sólo si no es sábado o domingo
    unless [0, 6].include?(Date.today.wday)
      Finding.transaction do
        users = Finding.unconfirmed_for_notification.inject([]) do |u, finding|
          u | finding.users.select do |user|
            user.notifications.not_confirmed.any? do |n|
              n.findings.include?(finding)
            end
          end
        end

        users.each do |user|
          Notifier.deliver_stale_notification user
        end
      end
    end
  end

  def self.mark_as_unanswered_if_necesary
    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include?(Date.today.wday)
      Finding.transaction do
        findings = Finding.confirmed_and_stale.reject do |finding|
          finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
        end

        findings |= Finding.unconfirmed_and_stale.reject do |finding|
          finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
        end

        users = findings.inject([]) do |u, finding|
          finding.update_attribute :state, Finding::STATUS[:unanswered]
          u | finding.users
        end

        users.each do |user|
          Notifier.deliver_unanswered_findings_notification user,
            findings.select { |f| f.users.include?(user) }
        end
      end
    end
  end

  def self.warning_users_about_expiration
    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include?(Date.today.wday)
      users = Finding.next_to_expire.inject([]) do |u, finding|
        u | finding.users.select { |u| u.can_act_as_audited? }
      end

      users.each do |user|
        Notifier.deliver_findings_expiration_warning(user,
          user.findings.next_to_expire)
      end
    end
  end

  private

  def add_finding_follow_up_header(pdf, organization, date = Date.today)
    pdf.open_object do |heading|
      font_size = 10
      font_height_size = pdf.font_height(font_size)
      y_top = pdf.page_height - (pdf.top_margin / 2)

      if organization.try(:image_model)
        pdf.add_image_from_file(
          organization.image_model.full_filename(:thumb),
          pdf.left_margin, pdf.absolute_top_margin + font_height_size,
          organization.image_model.thumb(:pdf_thumb).width,
          organization.image_model.thumb(:pdf_thumb).height)
      end

      date_text = I18n.l(date, :format => :long) if date
      text = I18n.t :'finding.follow_up_report.print_date', :date => date_text
      x_start = pdf.absolute_right_margin - pdf.text_width(text, font_size)
      pdf.add_text(x_start, y_top, text.to_iso, font_size)

      pdf.close_object
      pdf.add_object(heading, :all_pages)
    end
  end
end