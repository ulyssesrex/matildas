class Admin::SessionsController < ApplicationController
  # Allows an unauthenticated visitor to see and submit the admin login form
  allow_unauthenticated_access only: [ :new, :create ]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_admin_session_url, alert: "Try again later." }

  def new
    # Renders the native login form
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      # Verification step: ensure the authenticated user is an administrator
      if user.admin?
        start_new_session_for user
        redirect_to admin_root_path, notice: "Logged in to Admin Dashboard."
      else
        redirect_to new_admin_session_path, alert: "Access denied: Unauthorized account."
      end
    else
      redirect_to new_admin_session_path, alert: "Try again. Incorrect email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_admin_session_path, notice: "Logged out.", status: :see_other
  end
end
