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

class FeedController < ApplicationController
  LIMIT = 15
  
  include Raki::Helpers::ProviderHelper
  
  def global
    @changes = []
    namespaces.each do |namespace|
      @changes += page_changes(namespace, LIMIT)
      @changes += attachment_changes(namespace, LIMIT)
    end
    @changes = @changes.sort {|a,b| b.revision.date <=> a.revision.date}
    @changes = @changes[0..LIMIT]
    respond_to do |format|
      format.atom
    end
  end
  
  def namespace
    @namespace = params[:namespace]
    @changes = page_changes(@namespace, LIMIT)
    @changes += attachment_changes(@namespace, LIMIT)
    @changes = @changes.sort {|a,b| b.revision.date <=> a.revision.date}
    @changes = @changes[0..LIMIT]
    respond_to do |format|
      format.atom
    end
  end
  
  def page
    @namespace = params[:namespace]
    @page = params[:id]
    @revisions = page_revisions(@namespace, @page)[0..LIMIT]
    attachment_all(@namespace, @page).each do |attachment|
      @revisions += attachment_revisions(@namespace, @page, attachment)
    end
    @revisions = @revisions.sort {|a,b| b.date <=> a.date}
    @revisions = @revisions[0..LIMIT]
    respond_to do |format|
      format.atom
    end
  end
  
end
