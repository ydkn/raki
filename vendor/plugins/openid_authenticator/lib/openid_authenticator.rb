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

require 'rubygems'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'

class OpenIDAuthenticator < Raki::AbstractAuthenticator

  def login(params, session, cookies)
    openid = params[:openid]
    begin
      request = openid_consumer(session).begin(openid)
      sreg = OpenID::SReg::Request.new
      sreg.request_fields(['email','nickname'], true)
      request.add_extension(sreg)
      request.return_to_args['did_sreg'] = 'y'
      return request.redirect_url(
          url_for(:controller => 'page', :action => 'redirect_to_frontpage', :only_path => false),
          url_for(:controller => 'authentication', :action => 'callback', :only_path => false)
        )
    rescue => e
      raise AuthenticatorError.new("Unable to authenticate: #{openid}")
    end
  end

  def callback(params, session, cookies)
    begin
      response = openid_consumer(session).complete(params, url_for(:controller => 'authentication', :action => 'callback', :only_path => false))
    rescue => e
      raise AuthenticatorError.new(t 'auth.openid.invalid_response')
    end
    case response.status
      when OpenID::Consumer::FAILURE
        raise AuthenticatorError.new(t 'auth.openid.verification_failed')
      when OpenID::Consumer::SUCCESS
        sreg = OpenID::SReg::Response.from_success_response(response)
        raise AuthenticatorError.new(t 'auth.openid.no_sreg') if sreg.empty?
        raise AuthenticatorError.new(t 'auth.openid.nickname_email_missing') unless sreg.data.key?('nickname') && sreg.data.key?('email')
        return User.new(sreg.data['nickname'], sreg.data['email'])
      else
        raise AuthenticatorError.new(t 'auth.openid.invalid_response')
    end
    nil
  end

  def form_fields
    [
      {
        :name => 'openid',
        :type => 'text',
        :title => t('auth.openid')
      }
    ]
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
