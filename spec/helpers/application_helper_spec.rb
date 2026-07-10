require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  before do
    Current.reset
  end

  after do
    Current.reset
  end

  describe "#current_user" do
    it "returns nil when the request is not authenticated" do
      define_authenticated_helper(false)
      Current.session = Session.new(user: User.new(admin: true))

      expect(helper.current_user).to be_nil
    end

    it "returns the user from the current session when authenticated" do
      user = User.new(email_address: "admin@example.com", admin: true)

      define_authenticated_helper(true)
      Current.session = Session.new(user: user)

      expect(helper.current_user).to be(user)
    end
  end

  describe "#admin_session?" do
    it "returns true when the current user is an admin" do
      user = User.new(email_address: "admin@example.com", admin: true)

      define_authenticated_helper(true)
      Current.session = Session.new(user: user)

      expect(helper.admin_session?).to be(true)
    end

    it "returns false when the current user is not an admin" do
      user = User.new(email_address: "member@example.com", admin: false)

      define_authenticated_helper(true)
      Current.session = Session.new(user: user)

      expect(helper.admin_session?).to be(false)
    end

    it "returns false when the request is not authenticated" do
      define_authenticated_helper(false)

      expect(helper.admin_session?).to be(false)
    end
  end

  def define_authenticated_helper(authenticated)
    helper.define_singleton_method(:authenticated?) { authenticated }
  end
end
