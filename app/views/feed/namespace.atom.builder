atom_feed do |feed|

  feed.title h("#{Raki.app_name} :: #{@namespace}")
  feed.updated @revisions.first.date

  @revisions.each do |revision|
    if revision.type == :page
      entry_id = "#{revision.page.namespace}/#{revision.page.name}@#{revision.id}"
      entry_url = revision.page.url(:revision => revision, :force_revision => true)
    else
      entry_id = "#{revision.page.namespace}/#{revision.page.name}/#{revision.attachment.name}@#{revision.id}"
      entry_url = revision.attachment.url(:revision => revision, :force_revision => true)
    end
    feed.entry revision, :id => h(entry_id), :url => entry_url do |entry|
      if revision.type == :page
        entry.title h("#{revision.page.name} :: #{revision.message}")
      else
        entry.title h("#{revision.page.name}/#{revision.attachment.name} :: #{revision.message}")
      end
      entry.updated revision.date.xmlschema
      entry.content :type => 'html' do |content|
        if revision.type == :page
          content.h1 h(revision.page.name)
        else
          content.h1 h("#{revision.page.name}/#{revision.attachment.name}")
        end
        content.h2 h("#{revision.version}: #{revision.message}")
        content.div do |div|
          div.b "#{t 'page.info.version.user'}: "
          div.span h(revision.user.display_name)
        end
        content.div do |div|
          div.b "#{t 'page.info.version.size'}: "
          div.span h(revision.size)
        end
        if revision.type == :page
          page = Page.find(revision.page.namespace, revision.page.name, revision.id)
          content.br
          content.div format_diff(page.diff)
          content.br
          content.hr
          content.div << page.render(context)
        end
      end
      entry.author do |author|
        author.name h(revision.user.display_name)
        author.email h(revision.user.email) if revision.user.email
      end
    end
  end

end
