atom_feed do |feed|

  feed.title h "#{Raki.app_name} :: #{@namespace}/#{@page}"
  feed.updated @revisions.first.date

  @revisions.each do |revision|
    feed.entry revision, :url => url_for(:controller => 'page', :action => 'view', :namespace => h(@namespace), :id => h(@page), :revision => h(revision.id)) do |entry|
      entry.title h revision.message
      entry.updated revision.date.xmlschema
      diff = []
      page_diff(@namespace, @page, revision.id).lines.each do |line|
        diff << h(line)
      end
      entry.content %Q{
        <h1>#{h revision.version}: #{h revision.message}</h1>
        <div><b>Author: </b>#{h revision.user.display_name}</div>
        <div><b>Size: </b>#{h format_filesize(revision.size)}</div>
        <br />
        <div>#{diff.join('<br/>')}</div>
        <br />
        <hr />
        <div>#{insert_page @namespace, @page, revision.id}</div>
      }, :type => 'html'
      entry.author do |author|
        author.name h revision.user.display_name
      end
    end
  end

end