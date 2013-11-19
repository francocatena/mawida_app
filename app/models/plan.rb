class Plan < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: { organization_id: ->(obj) { Organization.current_id } }

  # Callbacks
  before_validation :set_proper_parent
  before_destroy :can_be_destroyed?

  # Atributos no persistentes
  attr_accessor :allow_overload, :allow_duplication, :new_version
  attr_writer :estimated_amount

  attr_readonly :period_id

  # Scopes
  scope :list, -> { where(organization_id: Organization.current_id) }

  # Restricciones
  validates :period_id, :organization, :presence => true
  validates :period_id, :uniqueness => true, :allow_nil => true,
    :allow_blank => true
  validates :period_id, :numericality => {:only_integer => true},
    :allow_nil => true
  validates_each :plan_items do |record, attr, value|
    unless value.all? {|pi| !pi.marked_for_destruction? || pi.can_be_destroyed?}
      record.errors.add attr, :locked
    end
  end

  # Relaciones
  belongs_to :period
  belongs_to :organization
  has_many :plan_items, -> { order("#{PlanItem.table_name}.order_number ASC") },
    :dependent => :destroy

  accepts_nested_attributes_for :plan_items, :allow_destroy => true

  def set_proper_parent
    self.plan_items.each { |pi| pi.plan = self }
  end

  def overloaded?
    self.plan_items.any? { |pi| pi.overloaded }
  end

  def has_duplication?
    has_duplication = false

    self.plan_items.each do |pi|
      errors = pi.errors
      @taken_error ||= ::ActiveModel::Errors.new(pi).generate_message(:project,
        :taken)

      has_duplication ||= errors[:project].include?(@taken_error)
    end

    has_duplication
  end

  def allow_overload?
    self.allow_overload == true || (self.allow_overload.respond_to?(:to_i) &&
      self.allow_overload.to_i != 0)
  end

  def allow_duplication?
    self.allow_duplication == true ||
      (self.allow_duplication.respond_to?(:to_i) &&
        self.allow_duplication.to_i != 0)
  end

  def estimated_amount(business_unit_type = nil)
    items = business_unit_type ?
      self.plan_items.for_business_unit_type(business_unit_type) :
      self.plan_items

    items.inject(0.0) do |sum, plan_item|
      sum + plan_item.resource_utilizations.to_a.sum(&:cost)
    end
  end

  def can_be_destroyed?
    unless self.plan_items.all? { |pi| pi.can_be_destroyed? }
      errors = self.plan_items.map do |pi|
        pi.errors.full_messages.join(APP_ENUM_SEPARATOR)
      end

      self.errors.add :base, errors.reject { |e| e.blank? }.join(
        APP_ENUM_SEPARATOR)

      false
    else
      true
    end
  end

  def clone_from(other)
    period = self.period
    diff_in_years = period ?
      (period.start.year - other.period.start.year).years : 0

    other.plan_items.each do |pi|
      attributes = pi.attributes.merge(
        'id' => nil,
        'resource_utilizations_attributes' =>
          pi.resource_utilizations.map { |ru| ru.attributes.merge 'id' => nil }
      ).with_indifferent_access

      if attributes[:start]
        item_start = attributes[:start] = attributes[:start] + diff_in_years
      end

      if attributes[:end]
        item_end = attributes[:end] = attributes[:end] + diff_in_years
      end

      if period
        attributes[:start] = period.start unless period.contains?(item_start)
        attributes[:end] = period.end unless period.contains?(item_end)
      end

      self.plan_items.build(attributes)
    end

    self.allow_overload, self.allow_duplication = true, true
  end

  def grouped_plan_items
    self.plan_items.group_by { |pi| pi.business_unit.try(:business_unit_type) }
  end

  def to_pdf(organization = nil, include_details = true)
    pdf = Prawn::Document.create_generic_pdf :landscape
    currency_mask = "#{I18n.t('number.currency.format.unit')}%.2f"
    column_order = [['order_number', 6], ['status', 6],
      ['business_unit_id', 16], ['project', 27], ['start', 7.5], ['end', 7.5],
      ['human_resources_cost', 10], ['material_resources_cost', 10],
      ['total_resources_cost', 10]]
    column_headers, column_widths = [], []

    pdf.add_generic_report_header organization

    pdf.add_title "#{I18n.t('plan.pdf.title')}\n", (PDF_FONT_SIZE * 1.5).round,
      :center

    pdf.add_description_item(I18n.t('plan.period.title',
        :number => self.period.number), I18n.t('plan.period.range',
        :from_date => I18n.l(self.period.start, :format => :long),
        :to_date => I18n.l(self.period.end, :format => :long)), 0, false)

    column_order.each do |col_name, col_with|
      column_headers << "<b>#{PlanItem.human_attribute_name(col_name)}</b>"
      column_widths << pdf.percent_width(col_with)
    end

    grouped_plan_items = self.grouped_plan_items

    (BusinessUnitType.list + [nil]).each do |but|
      items = (grouped_plan_items[but] || []).sort
      column_data = []
      total_cost = 0.0

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title but.try(:name) || I18n.t('plan.without_business_unit_type')

      items.each do |plan_item|
        total_resource_text = currency_mask % plan_item.cost
        total_cost += plan_item.cost

        column_data << [
          plan_item.order_number,
          plan_item.status_text(false),
          plan_item.business_unit ?
            plan_item.business_unit.name : '',
          plan_item.project,
          I18n.l(plan_item.start, :format => :default),
          I18n.l(plan_item.end, :format => :default),
          currency_mask % plan_item.human_cost,
          currency_mask % plan_item.material_cost,
          total_resource_text
        ]
      end

      column_data << [
        '', '', '', '', '', '', '', '', "<b>#{currency_mask % total_cost}</b>"
      ]

      pdf.move_down PDF_FONT_SIZE

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      end

      pdf.text "\n#{I18n.t('plan.item_status.note')}",
        :font_size => (PDF_FONT_SIZE * 0.75).round

      if include_details &&
          !items.all? { |pi| pi.resource_utilizations.blank? }
        pdf.move_down PDF_FONT_SIZE

        pdf.add_title I18n.t('plan.pdf.resource_utilization'),
          (PDF_FONT_SIZE * 1.25).round

        items.each do |plan_item|
          unless plan_item.resource_utilizations.blank?
            plan_item.add_resource_data(pdf)
          end
        end
      end
    end

    pdf.custom_save_as(self.pdf_name, Plan.table_name, self.id)
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path(self.pdf_name, Plan.table_name, self.id)
  end

  def relative_pdf_path
    Prawn::Document.relative_path(self.pdf_name, Plan.table_name, self.id)
  end

  def pdf_name
    I18n.t('plan.pdf.pdf_name', :period => self.period.number)
  end

  def cost
    self.plan_items.inject(0.0) { |sum, pi| sum + pi.cost }
  end
end
