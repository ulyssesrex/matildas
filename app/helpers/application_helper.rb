module ApplicationHelper
  def current_user
    return unless authenticated?

    Current.session&.user
  end

  def admin_session?
    current_user&.admin? == true
  end
end
