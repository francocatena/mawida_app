class ResourceUtilization < ActiveRecord::Base
  include Auditable
  include Comparable
  include ParameterSelector
  include ResourceUtilizations::Scopes
  include ResourceUtilizations::Validation

  belongs_to :resource, polymorphic: true
  belongs_to :resource_consumer, polymorphic: true

  def <=>(other)
    if other.kind_of?(ResourceUtilization)
      resource_id <=> other.resource_id
    else
      -1
    end
  end

  def human?
    resource_type == 'User'
  end

  def material?
    resource_type == 'Resource'
  end
end
