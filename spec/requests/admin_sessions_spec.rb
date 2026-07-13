require 'rails_helper'

RSpec.describe "Admin sessions", type: :request do
  describe "DELETE /admin/session" do
    it "redirects unauthenticated visitors to the admin login page" do
      delete admin_session_path

      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "POST /admin/session" do
    let!(:admin) do
      User.create!(
        email_address: "Admin.User@Example.COM",
        password: "MiXeD-Pass9",
        password_confirmation: "MiXeD-Pass9",
        admin: true
      )
    end

    it "normalizes email casing and accepts the exact mixed-case password" do
      expect(admin.reload.email_address).to eq("admin.user@example.com")

      post admin_session_path, params: {
        email_address: "ADMIN.USER@example.com",
        password: "MiXeD-Pass9"
      }

      expect(response).to redirect_to(root_path)
    end

    it "keeps passwords case-sensitive" do
      post admin_session_path, params: {
        email_address: "admin.user@example.com",
        password: "mixed-pass9"
      }

      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
