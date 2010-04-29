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

require 'rubygems'
require 'openid'
require 'openid/store/filesystem'

class OpenIDAuthenticator < Raki::AbstractAuthenticator

  def login(username, password, session)
    controller = Raki.controller
    begin
      request = openid_consumer(session).begin(username)
      request.add_extension_arg('sreg', 'required', 'nickname,email')
      return request.redirect_url(controller.url_for(''), controller.url_for(:controller => 'authentication', :action => 'callback'))
    rescue
      raise AuthenticatorError.new("Unable to authenticate against: #{username}")
    end
  end

  def callback(params, session)
    controller = Raki.controller
    response = openid_consumer(session).complete(params, controller.url_for(:controller => 'authentication', :action => 'callback'))
    if response.status == :success
      user = User.new
      user.username = params['openid.sreg.nickname']
      user.email = params['openid.sreg.email']
      return user
    end
    nil
  end

  private

  def openid_consumer(session)
    @openid_consumer = OpenID::Consumer.new(
      session,
      OpenID::Store::Filesystem.new("#{RAILS_ROOT}/tmp/openid")
    ) if @openid_consumer.nil?
    @openid_consumer
  end

end