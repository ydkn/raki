atom_feed do |feed|

  feed.title h "#{Raki.app_name}"
  
  updated = nil
  @changes.each do |change|
    next unless authorized?(change.type, change.page, :view)
    updated = change.revision.date if updated.nil?    
    if change.attachment.nil?
      feed.entry change.revision, :url => url_for(:controller => 'page', :action => 'view', :type => h(change.type), :id => h(change.page), :revision => h(change.revision.id)) do |entry|
        entry.title h "#{change.type}/#{change.page}"
        entry.updated change.revision.date.xmlschema
        diff = []
        Raki.provider(change.type).page_diff(change.type, change.page, change.revision.id).lines.each do |line|
          diff << h(line)
        end
        entry.content %Q{
          <h1>#{h change.type}/#{h change.page}</h1>
          <h2>#{h change.revision.version}: #{h change.revision.message}</h2>
          <div><b>Author: </b>#{h change.revision.user.display_name}</div>
          <div><b>Size: </b>#{h format_size(change.revision.size)}</div>
          <br />
          <div>#{diff.join('<br/>')}</div>
          <br />
          <hr />
          <div>#{insert_page change.type, change.page, change.revision.id}</div>
        }, :type => 'html'
        entry.author do |author|
          author.name h change.revision.user.display_name
        end
      end
    else
      feed.entry change.revision, :url => url_for(:controller => 'page', :action => 'attachment', :type => h(change.type), :id => h(change.page), :attachment => h(change.attachment), :revision => h(change.revision.id)) do |entry|
        entry.title h "#{change.type}/#{change.page}/#{change.attachment}"
        entry.updated change.revision.date.xmlschema
        entry.content %Q{
          <h1>#{h change.type}/#{h change.page}/#{h change.attachment}</h1>
          <h2>#{h change.revision.version}: #{h change.revision.message}</h2>
          <div><b>Author: </b>#{h change.revision.user.display_name}</div>
          <div><b>Size: </b>#{h format_size(change.revision.size)}</div>
        }, :type => 'html'
        entry.author do |author|
          author.name h change.revision.user.display_name
        end
      end
    end
  end
  
  feed.updated updated

end
