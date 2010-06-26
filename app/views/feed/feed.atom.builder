atom_feed do |feed|

  feed.title h "#{Raki.app_name}"
  feed.updated @changes.last.revision.date

  @changes.reverse_each do |change|
    if change.attachment.nil?
      feed.entry change.revision, :url => url_for(:controller => 'page', :action => 'view', :type => h(change.type), :id => h(change.name), :revision => h(change.revision.id)) do |entry|
        entry.title change.name
        entry.content change.revision.message, :type => 'html'
        entry.author do |author|
          author.name h change.revision.user
        end
      end
    else
      feed.entry change.revision, :url => url_for(:controller => 'page', :action => 'attachment', :type => h(change.type), :id => h(change.name), :attachment => h(change.attachment), :revision => h(change.revision.id)) do |entry|
        entry.title change.name
        entry.content change.revision.message, :type => 'html'
        entry.author do |author|
          author.name h change.revision.user
        end
      end
    end
  end

end
