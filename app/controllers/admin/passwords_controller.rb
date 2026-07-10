class Admin::PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: [ :edit, :update ]

  def new
    # Renders request form
  end

  def create
    # Find the user, but strictly ensure they are an administrator
    if user = User.find_by(email_address: params[:email_address])
      if user.admin?
        PasswordsMailer.reset(user).deliver_later
        redirect_to new_admin_session_path, notice: "Password reset instructions sent."
      else
        redirect_to new_admin_password_path, alert: "Unauthorized account request."
      end
    else
      redirect_to new_admin_password_path, alert: "Email address not found."
    end
  end

  def edit
    # Renders actual reset form
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_admin_session_path, notice: "Password reset successful. Please sign in."
    else
      redirect_to edit_admin_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private

  def set_user_by_token
    # Scopes token verification specifically to admin users
    @user = User.find_by_token_for!(:password_reset, params[:token])

    unless @user.admin?
      redirect_to new_admin_session_path, alert: "Invalid access token clearance."
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_admin_password_path, alert: "Password reset link is invalid or expired."
  end
end
