# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class ApplicationController < ActionController::Base
  #protect_from_forgery

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  helper PageHelper
  helper AuthenticationHelper

  before_filter :init_raki
  before_filter :try_to_authenticate_user

  private

  def init_raki
    Raki::Helpers.init self
    @context = {}
  end

  def try_to_authenticate_user
    User.current = nil
    begin
      unless session[:user].nil?
        user = session[:user]
        if user.is_a?(User)
          User.current = user
        end
      end
    rescue
      User.current = nil
    end
  end

end
