require 'rails_helper'

RSpec.describe "Admin sessions", type: :request do
  describe "POST /admin/session" do
    it "redirects successful admin logins to the public home page" do
      User.create!(
        email_address: "admin@example.com",
        password: "password",
        password_confirmation: "password",
        admin: true
      )

      post admin_session_path, params: {
        email_address: "admin@example.com",
        password: "password"
      }

      expect(response).to redirect_to(root_path)
    end
  end
end
