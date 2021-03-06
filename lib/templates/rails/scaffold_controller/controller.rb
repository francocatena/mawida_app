<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  respond_to :html, :json

  before_action :auth, :check_privileges
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET <%= route_url %>
  def index
    @<%= plural_table_name %> = <%= orm_class.all class_name %>
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build class_name %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build class_name, "#{singular_table_name}_params" %>

    @<%= orm_instance.save %>
    respond_with @<%= singular_table_name %>
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    update_resource @<%= singular_table_name %>, <%= "#{singular_table_name}_params" %>
    respond_with @<%= singular_table_name %>
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    respond_with @<%= singular_table_name %>
  end

  private

    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find class_name, 'params[:id]' %>
    end

    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params[<%= ":#{singular_table_name}" %>]
      <%- else -%>
      params.require(<%= ":#{singular_table_name}" %>).permit <%= attributes_names.map { |name| ":#{name}" }.join(', ') %>
      <%- end -%>
    end
end
<% end -%>
