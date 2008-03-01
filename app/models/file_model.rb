class FileModel < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  has_attachment :storage => :file_system, :max_size => 20.megabytes,
    :path_prefix => "#{PRIVATE_FILES_PREFIX}/#{table_name}"
  
  # Restricciones
  validates_as_attachment
  validates_length_of :filename, :content_type, :maximum => 255,
    :allow_nil => true, :allow_blank => true

  def base_path
    RAILS_ROOT
  end
end