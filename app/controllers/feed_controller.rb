class FeedController < ApplicationController
  
  def feed
    days = {}
    provider_types.each do |type|
      page_changes(type).each do |change|
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
      attachment_changes(type).each do |change|
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
    end
    days = days.sort { |a,b| b <=> a }
    out = ""
    @changes = []
    days.each do |day,changes|
      changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
      changes.each do |change|
        @changes << change
      end
    end
    respond_to do |format|
      format.atom
    end
  end
  
  private
  
  def provider_types
    types = []
    Raki.providers.keys.each do |provider|
      types += Raki.provider(provider).types
    end
    types
  end

  def page_changes(type, limit=nil)
    return Raki.provider(type).page_changes(type, limit)
  end
  
  def attachment_changes(type, limit=nil)
    changes = []
    Raki.provider(type).page_all(type).each do |page|
      changes += Raki.provider(type).attachment_changes(type, page, limit)
    end
    changes
  end
  
end
