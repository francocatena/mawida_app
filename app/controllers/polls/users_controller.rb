class Polls::UsersController < ApplicationController
  before_action :auth

  respond_to :json

  def index
    @users = current_organization.users.where.
      not("#{User.table_name}.id = ?", current_user).
      search(params[:q]).limit(10)

    respond_with @users
  end
end
