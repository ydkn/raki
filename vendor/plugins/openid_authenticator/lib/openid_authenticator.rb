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
require 'openid/extensions/ax'

class OpenIDAuthenticator < Raki::AbstractAuthenticator

  def login(params, session, cookies)
    openid = params[:openid]
    begin
      request = openid_consumer(session).begin(openid)
      sreg = OpenID::SReg::Request.new
      sreg.request_fields(['email','nickname'], true)
      request.add_extension(sreg)
      ax = OpenID::AX::FetchRequest.new
      ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/contact/email', 'email', true))
      if openid =~ /google\.com\//
        ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/first', 'firstname', true))
        ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/last', 'lastname', true))
      else
        ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/friendly', 'nickname', true))
      end
      request.add_extension(ax)
      return request.redirect_url(
          url_for(:controller => 'page', :action => 'redirect_to_frontpage', :only_path => false),
          url_for(:controller => 'authentication', :action => 'callback', :only_path => false)
        )
    rescue => e
      raise AuthenticatorError.new(t 'auth.openid.unable_to_authenticate', :openid => h(openid))
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
        nickname, email = parse_sreg_response(response)
        if nickname.nil? || email.nil?
          nickname2, email2 = parse_ax_response(response)
          nickname = nickname2 if nickname.nil?
          email = email2 if email.nil?
        end
        raise AuthenticatorError.new(t 'auth.openid.nickname_email_missing') if nickname.nil? || email.nil?
        return User.new(nickname, email)
      when OpenID::Consumer::SETUP_NEEDED
        raise AuthenticatorError.new(t 'auth.openid.setup_needed')
      when OpenID::Consumer::CANCEL
        raise AuthenticatorError.new(t 'auth.openid.transaction_cancelled')
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
        :title => t('auth.openid.label')
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
  
  def parse_sreg_response(response)
    begin
      sreg = OpenID::SReg::Response.from_success_response(response)
      return sreg.data['nickname'], sreg.data['email']
    rescue => e
      return nil, nil
    end
  end
  
  def parse_ax_response(response)
    begin
      ax = OpenID::AX::FetchResponse.from_success_response(response)
      nickname = ax.data['http://axschema.org/namePerson/friendly'].first
      if nickname.nil? && !ax.data['http://axschema.org/namePerson/first'].first.nil?
        nickname = ax.data['http://axschema.org/namePerson/first'].first
        unless ax.data['http://axschema.org/namePerson/last'].first.nil?
          nickname += " #{ax.data['http://axschema.org/namePerson/last'].first}"
        end
      end
      return nickname, ax.data['http://axschema.org/contact/email'].first
    rescue => e
      return nil, nil
    end
  end

end
