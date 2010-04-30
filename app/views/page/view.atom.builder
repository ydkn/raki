atom_feed do |feed|

  feed.title h "#{Raki.app_name}"
  feed.updated @revisions.last.date

  @revisions.reverse_each do |revision|
    feed.entry revision, :url => url_for(:controller => 'page', :action => 'view', :revision => revision.id) do |entry|
      entry.title revision.message
      entry.content revision.message, :type => 'html'
      entry.author do |author|
        author.name h revision.user
      end
    end
  end

end