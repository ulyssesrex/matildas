class Admin::BaseController < ApplicationController
  before_action :ensure_admin_clearance!

  private

  def ensure_admin_clearance!
    # If they are logged in but lack the admin boolean flag, block them
    unless Current.user&.admin?
      redirect_to new_admin_session_path, alert: "You must be an administrator to access this area."
    end
  end
end
