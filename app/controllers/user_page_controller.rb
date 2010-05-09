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

class UserPageController < ApplicationController
  before_filter :common_init

  def redirect_to_userpage
    if User.current.nil?
      redirect_to :controller => 'page', :action => 'view', :id => Raki.frontpage
    else
      redirect_to :controller => 'user_page', :action => 'view', :id => User.current.username
    end
  end

  def view
    current_revision = @provider.userpage_revisions(@user).last
    @page_info = {
      :date => current_revision.date,
      :user => current_revision.user,
      :version => current_revision.version,
      :type => 'user_page',
      :id => @user
    } unless current_revision.nil?
    respond_to do |format|
      format.html
      format.atom { @revisions = @provider.userpage_revisions @user }
      format.txt { render :inline => @provider.userpage_contents(@user, @revision), :content_type => 'text/plain' }
    end
  end

  def info
    return if redirect_if_userpage_not_exists
    @revisions = @provider.userpage_revisions @user
    respond_to do |format|
      format.html
    end
  end

  def edit
    if params[:content].nil?
      @content = @provider.userpage_contents(@user, @revision)
    else
      @content = params[:content]
      @preview = @content
    end
  end

  def update
    @provider.userpage_save @user, params[:content], params[:message], User.current
    redirect_to :controller => 'user_page', :action => 'view', :id => @user
  end

  def attachments
    @attachments = []
    @provider.userpage_attachment_all(@user).each do |attachment|
      @attachments << {
        :name => attachment,
        :revision => @provider.userpage_attachment_revisions(@user, attachment).last
      }
    end
    @attachments.sort { |a,b| a[:name] <=> b[:name] }
  end

  def attachment_upload
    @provider.userpage_attachment_save(
      @user,
      File.basename(params[:attachment_upload].original_filename),
      params[:attachment_upload].read,
      params[:message],
      User.current
    )
    redirect_to :controller => 'user_page', :action => 'attachments', :id => @user
  end

  def attachment
    # ugly fix for ruby1.9 and rails2.5
    revision = @provider.userpage_attachment_revisions(@user, @attachment).last.id if @revision.nil?
    unless File.exists? "#{Rails.root}/tmp/attachments/users/#{@user}/#{revision}/#{@attachment}"
      FileUtils.mkdir_p "#{Rails.root}/tmp/attachments/users/#{@user}/#{revision}"
      File.open "#{Rails.root}/tmp/attachments/users/#{@user}/#{revision}/#{@attachment}", 'w' do |f|
        f.write(@provider.userpage_attachment_contents(@user, @attachment, @revision))
      end
    end
    send_file "#{Rails.root}/tmp/attachments/users/#{@user}/#{revision}/#{@attachment}"
  end
  
  private

  def common_init
    @user = params[:id]
    @revision = params[:revision]
    @attachment = params[:attachment].join '' unless params[:attachment].nil?
    @provider = Raki.provider(:userpage)
    @title = @user
  end

  def redirect_if_userpage_not_exists
    unless @provider.userpage_exists?(@user)
      redirect_to :controller => 'user_page', :action => 'view', :id => @user
      true
    end
    false
  end

end
