# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
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
  protect_from_forgery

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  helper PageHelper
  helper AuthenticationHelper

  before_filter :try_to_authenticate_user, :set_locale, :init_context

  private

  def init_context
    @context = {
      :params => params
    }
  end

  def try_to_authenticate_user
    User.current = AnonymousUser.new request.remote_ip
    if Raki::Authenticator.respond_to? :try_to_authenticate
      Raki::Authenticator.try_to_authenticate params, session, cookies
    end
    unless session[:user].nil?
      User.current = session[:user] if session[:user].is_a?(User)
    end
  end
  
  def set_locale
    I18n.locale = I18n.default_locale
    begin
      if request.accept_language
        request.accept_language.split(',').each do |lang|
          lang = lang.split(';').first.strip
          if I18n.available_locales.include?(lang.to_sym)
            I18n.locale = lang.to_sym
            break
          end
          lang = lang.split('-').first
          if I18n.available_locales.include?(lang.to_sym)
            I18n.locale = lang.to_sym
            break
          end
        end
      end
    rescue => e
      # ignore
    end
  end

end
