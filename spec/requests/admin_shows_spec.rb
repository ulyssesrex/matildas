require "rails_helper"

RSpec.describe "Admin shows", type: :request do
  describe "POST /admin/shows" do
    it "redirects unauthenticated visitors to the admin login page" do
      post admin_shows_path, params: { admin_show_form: {} }

      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
