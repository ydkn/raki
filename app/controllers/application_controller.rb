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

  helper AuthenticationHelper
  helper PageHelper
  helper ParseHelper

  before_filter :init_url_helper, :init_visited_pages, :try_to_authenticate_user, :set_locale, :init_context

  private
  
  def init_visited_pages
    session[:visited_pages] = [] if session[:visited_pages].nil?
  end
  
  def init_url_helper
    Raki::Helpers::URLHelper.host = request.host
    Raki::Helpers::URLHelper.port = request.port
  end

  def init_context
    @context = {
      :params => params,
      :subcontext => {}
    }
  end

  def try_to_authenticate_user
    User.current = nil
    if Raki::Authenticator.respond_to? :validate_session
      res = Raki::Authenticator.validate_session params, session, cookies
      if res.is_a?(String)
        redirect_to res
      elsif res.is_a?(User)
        User.current = res
      end
    elsif session[:user] && session[:user].is_a?(User)
      User.current = session[:user]
    end
    User.current = AnonymousUser.new request.remote_ip unless User.current
    session[:user] = User.current
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
    end
  end

end
