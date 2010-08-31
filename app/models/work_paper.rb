class WorkPaper < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Named scopes
  scope :with_prefix, lambda { |prefix|
    {
      :conditions => ['code LIKE :code', { :code => "#{prefix}%" }],
      :order => 'code ASC'
    }
  }
  scope :sorted_by_code, :order => 'code ASC'

  # Restricciones de los atributos
  attr_accessor :code_prefix, :neighbours
  attr_readonly :organization_id, :code
  attr_accessor_with_default :check_code_prefix, true

  # Callbacks
  before_save :check_for_modifications
  after_save :create_cover_and_zip
  
  # Restricciones
  validates_presence_of :organization_id, :name, :code, :number_of_pages
  validates_numericality_of :number_of_pages, :only_integer => true,
    :allow_nil => true, :allow_blank => true, :less_than => 100000
  validates_numericality_of :organization_id, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validates_length_of :name, :code, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_each :code, :on => :create do |record, attr, value|
    if record.check_code_prefix
      raise 'No code_prefix is set!' unless record.code_prefix

      regex = Regexp.new "\\A(#{record.code_prefix})\\s\\d+\\Z"

      record.errors.add attr, :invalid unless value =~ regex

      raise 'The neighbours array is not set!' unless record.neighbours

      taken_codes = []

      record.neighbours.each do |wp|
        another_work_paper = (!record.new_record? && record.id != wp.id) ||
          (record.new_record? && record.object_id != wp.object_id)

        if another_work_paper && !record.marked_for_destruction? &&
            record.code.strip == wp.code.strip
          taken_codes << record.code.strip
        end
      end

      unless taken_codes.blank?
        record.errors.add attr, :taken
      end
    end
  end
  
  # Relaciones
  belongs_to :organization
  belongs_to :file_model, :dependent => :destroy
  belongs_to :owner, :polymorphic => true

  accepts_nested_attributes_for :file_model, :allow_destroy => true

  def inspect
    "#{self.code} - #{self.name} (#{self.pages_to_s})"
  end

  def pages_to_s
    I18n.t(:'work_paper.number_of_pages', :count => self.number_of_pages)
  end

  def check_for_modifications
    @zip_must_be_created = self.file_model.try(:new_record?) ||
      self.file_model.try(:changed?)
    @cover_must_be_created = self.changed?

    true
  end

  def create_cover_and_zip
    self.create_pdf_cover if @cover_must_be_created && self.file_model

    if @zip_must_be_created || (@cover_must_be_created && self.file_model)
      self.create_zip
    end
    
    true
  end

  def create_pdf_cover(filename = nil, review = nil)
    review ||= self.owner.kind_of?(ControlObjectiveItem) ? self.owner.review :
      (self.owner.kind_of?(Finding) ?
        self.owner.try(:control_objective_item).try(:review) : nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)

    pdf.add_review_header review.try(:organization),
      review.try(:identification), review.try(:plan_item).try(:project)

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_title WorkPaper.human_name, PDF_FONT_SIZE * 2, :full, true

    pdf.move_pointer PDF_FONT_SIZE * 4

    unless self.name.blank?
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name('name'),
        self.name, 0, false
    end

    unless self.description.blank?
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name('description'),
        self.description, 0, false
    end

    unless self.code.blank?
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name('code'),
        self.code, 0, false
    end

    unless self.number_of_pages.blank?
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(
        'number_of_pages'), self.number_of_pages.to_s, 0, false
    end

    pdf.save_as self.absolute_cover_path(filename)
  end

  def pdf_cover_name(filename = nil)
    filename ||= self.file_model.filename if self.file_model

    unless filename.starts_with?(self.sanitized_code)
      I18n.t :'work_paper.cover_name', :prefix => "#{self.sanitized_code}-",
        :filename => File.basename(filename, File.extname(filename))
    else
      I18n.t :'work_paper.cover_name', :prefix => "",
        :filename => File.basename(filename, File.extname(filename))
    end
  end

  def absolute_cover_path(filename = nil)
    if self.file_model
      File.join File.dirname(self.file_model.full_filename), self.pdf_cover_name
    else
      "#{TEMP_PATH}#{self.pdf_cover_name(filename || self.object_id.abs)}"
    end
  end

  def filename_with_prefix
    filename = self.file_model.filename

    filename.starts_with?(self.sanitized_code) ?
      filename : "#{self.sanitized_code}-#{filename}"
  end

  def create_zip
    self.unzip_if_necesary

    original_filename = self.file_model.full_filename
    directory = File.dirname original_filename
    filename = File.basename original_filename, File.extname(original_filename)
    pdf_filename = self.absolute_cover_path
    zip_filename = File.join directory,
      (filename.start_with?(self.sanitized_code) ?
        "#{filename}.zip" : "#{self.sanitized_code}-#{filename}.zip")

    self.create_pdf_cover unless File.exist?(pdf_filename)

    if File.file?(original_filename) && File.file?(pdf_filename)
      Zip::ZipFile.open(zip_filename, Zip::ZipFile::CREATE) do |zipfile|
        zipfile.add(self.filename_with_prefix, original_filename) { true }
        zipfile.add(File.basename(pdf_filename), pdf_filename) { true }
      end

      FileUtils.rm [original_filename, pdf_filename]
      
      self.file_model.update_attributes(
        :filename => File.basename(zip_filename),
        :content_type => 'application/zip',
        :size => File.size(zip_filename)
      )
    end

    FileUtils.chmod 0640, zip_filename if File.exist?(zip_filename)
  end

  def unzip_if_necesary
    if self.file_model && File.extname(self.file_model.filename) == '.zip'
      zip_path = self.file_model.full_filename
      base_dir = File.dirname self.file_model.full_filename

      Zip::ZipFile.foreach(zip_path) do |entry|
        if entry.file?
          full_filename = File.join base_dir, entry.name
          ext = File.extname(full_filename)[1..-1]

          unless full_filename == zip_path || File.exist?(full_filename)
            entry.extract(full_filename)
          end

          if File.basename(full_filename, File.extname(full_filename)) ==
              File.basename(self.file_model.filename, '.zip')
            self.file_model.filename = File.basename(full_filename)
            self.file_model.content_type = Mime::Type.lookup_by_extension ext
            self.file_model.size = File.size(full_filename)
          end
        end
      end

      FileUtils.rm zip_path
    end
  end

  def sanitized_code
    self.code.gsub(/[^A-Za-z0-9\.\-]+/, '_')
  end
end