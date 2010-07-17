atom_feed do |feed|

  feed.title h "#{Raki.app_name} :: #{@type}/#{@page}"
  feed.updated @revisions.last.date

  @revisions.reverse_each do |revision|
    feed.entry revision, :url => url_for(:controller => 'page', :action => 'view', :type => h(@type), :id => h(@page), :revision => h(revision.id)) do |entry|
      entry.title h revision.message
      entry.updated revision.date.xmlschema
      entry.content %Q{
        <h1>#{h revision.version}: #{h revision.message}</h1>
        <div><b>Author: </b>#{h revision.user}</div>
        <div><b>Size: </b>#{h format_size(revision.size)}</div>
        <br />
        <div>#{@provider.page_diff(@type, @page, revision.id).lines.join("<br/>")}</div>
        <br />
        <hr />
        <div>#{insert_page @type, @page, revision.id}</div>
      }, :type => 'html'
      entry.author do |author|
        author.name h revision.user
      end
    end
  end

end