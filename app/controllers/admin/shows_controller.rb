class Admin::ShowsController < ApplicationController
  before_action :require_admin

  def create
    head :not_implemented
  end
end
