class PlayerController < ApplicationController
  before_action :authenticate_user! # TODO: Move this into ApplicationController once we've migrated all SYT routes over

  def index

  end
end