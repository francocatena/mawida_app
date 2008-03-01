class FileModelsController < ApplicationController
  before_filter :auth
  
  def download
    redirect = true

    file_name = File.expand_path(File.join(PRIVATE_PATH, params[:path] || ''))
    base_regexp = %r(^#{Regexp.escape(PRIVATE_PATH)})

    if file_name =~ base_regexp && File.file?(file_name)
      send_file file_name, :x_sendfile => (RAILS_ENV == 'production')
      redirect = false
    end

    redirect_to :controller => :users, :action => :index if redirect
  end
end