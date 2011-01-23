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
  
  include Raki::Helpers::URLHelper
  include Raki::Helpers::I18nHelper
  include ERB::Util

  def login(params, session, cookies)
    openid = params[:openid]
    begin
      request = openid_consumer(session).begin(openid)
      sreg = OpenID::SReg::Request.new
      sreg.request_fields(['nickname'], true)
      sreg.request_fields(['email', 'fullname'], false)
      request.add_extension(sreg)
      ax = OpenID::AX::FetchRequest.new
      ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/friendly', 'nickname', true))
      ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/contact/email', 'email', false))
      required = openid =~ /^https?:\/\/www\.google\.com\//
      ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/first', 'firstname', required))
      ax.add(OpenID::AX::AttrInfo.new('http://axschema.org/namePerson/last', 'lastname', required))
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
        sreg = parse_sreg_response(response)
        ax = parse_ax_response(response)
        fields = sreg.merge(ax)
        fields[:nickname] = fields[:fullname] if fields[:nickname].nil?
        raise AuthenticatorError.new(t 'auth.openid.nickname_missing') if fields[:nickname].nil?
        return User.new(fields[:nickname], :username => fields[:nickname], :email => fields[:email], :display_name => fields[:fullname])
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
  
  def user_for(options)
    id = options[:id] || options[:username]
    User.new(id, :username => options[:username], :email => options[:email], :display_name => options[:display_name])
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
      return {} if sreg.nil?
      fields = {}
      fields[:email] = sreg.data['email'] unless sreg.data['email'].nil?
      fields[:nickname] = sreg.data['nickname'] unless sreg.data['nickname'].nil?
      fields[:fullname] = sreg.data['fullname'] unless sreg.data['fullname'].nil?
      fields
    rescue => e
      return {}
    end
  end
  
  def parse_ax_response(response)
    begin
      ax = OpenID::AX::FetchResponse.from_success_response(response)
      return {} if ax.nil?
      fields = {}
      fields[:email] = ax.data['http://axschema.org/contact/email'].first unless ax.data['http://axschema.org/contact/email'].first.nil?
      fields[:nickname] = ax.data['http://axschema.org/namePerson/friendly'].first unless ax.data['http://axschema.org/namePerson/friendly'].first.nil?
      if !ax.data['http://axschema.org/namePerson/first'].first.nil? && !ax.data['http://axschema.org/namePerson/last'].first.nil?
        fields[:fullname] = "#{ax.data['http://axschema.org/namePerson/first'].first} #{ax.data['http://axschema.org/namePerson/last'].first}"
      end
      fields
    rescue => e
      return {}
    end
  end

end
