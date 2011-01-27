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

require 'test_helper'
require 'raki_syntax/node'

class RakiParserTest < Test::Unit::TestCase

  # Initializes the parser
  def setup
    @parser = RakiParser.new unless @parser
    @context = {:page => Page.new(:namespace => 'test', :name => 'unit')}
    [[:test, :WikiPageName], [:test, :link]].each do |namespace, name|
      unless Page.exists? namespace, name
        page = Page.new :namespace => namespace, :name => name
        page.content = 'raki_parser test page'
        page.save default_user, 'test'
      end
    end
  end

  def test_text
    assert_equal '', parse('')
    assert_equal "\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ", parse("\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end

  # Test linebreaks
  def test_linebreaks
    assert_equal "test<br/>text<br/>hallo", parse("test\ntext\n\nhallo")
    assert_equal "test<br/>text<br/>hallo", parse("test\r\ntext\r\n\r\nhallo")
    assert_equal "test<br/>text<br/><br/>hallo", parse("test\ntext\n\n\nhallo")
    assert_equal "test\ntext<br/>hallo", parse("test\\\ntext\n\nhallo")
  end

  def test_hline
    assert_equal "<hr/>", parse("----")
    assert_equal "test<hr/>text", parse("test\n----\ntext")
  end

  # Test links for wikipages
  def test_link_to_page
    assert_equal '<a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a>', parse("[WikiPageName]")
    assert_equal '<a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a>', parse("[ WikiPageName  ]")
    assert_equal '<a href="/test/WikiPageName" title="title for link">title for link</a>', parse("[WikiPageName|title for link]")
    assert_equal '<a class="inexistent" href="/wiki/WikiPageName" title="wiki/WikiPageName">wiki/WikiPageName</a>', parse("[wiki/WikiPageName]")
    assert_equal '<a class="inexistent" href="/wiki/WikiPageName" title="wiki/WikiPageName">wiki/WikiPageName</a>', parse("[ wiki/WikiPageName  ]")
    assert_equal '<a class="inexistent" href="/wiki/WikiPageName" title="title for link">title for link</a>', parse("[wiki/WikiPageName|title for link]")
  end
  
  # Test links for image attachments
  def test_link_to_image_attachment
    a = Attachment.new(:namespace => 'wiki', :page => 'WikiPageName', :name => 'some_image.png')
    a.content = 'content'
    a.save!(default_user, 'msg')
    
    assert_equal '<a href="/wiki/WikiPageName/attachment/some_image.png" title="some_image.png"><img src="/wiki/WikiPageName/attachment/some_image.png" alt="some_image.png" title="some_image.png"/></a>', parse("[some_image.png]", @context.merge({:page => Page.new(:namespace => 'wiki', :name => 'WikiPageName')}))
    assert_equal '<a href="/wiki/WikiPageName/attachment/some_image.png" title="WikiPageName/some_image.png"><img src="/wiki/WikiPageName/attachment/some_image.png" alt="WikiPageName/some_image.png" title="WikiPageName/some_image.png"/></a>', parse("[WikiPageName/some_image.png]", @context.merge({:page => Page.new(:namespace => 'wiki', :name => 'OtherWikiPageName')}))
    assert_equal '<a href="/wiki/WikiPageName/attachment/some_image.png" title="wiki/WikiPageName/some_image.png"><img src="/wiki/WikiPageName/attachment/some_image.png" alt="wiki/WikiPageName/some_image.png" title="wiki/WikiPageName/some_image.png"/></a>', parse("[wiki/WikiPageName/some_image.png]")
  end

  # Test links for urls
  def test_link
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("[http://github.com/ydkn/raki]")
    assert_equal '<a href="http://github.com/ydkn/raki">Raki on github</a>', parse("[http://github.com/ydkn/raki|Raki on github]")
    assert_equal '<a href="http://raki.ydkn.de/page/raki]|test"> foo]bar</a>', parse("[http://raki.ydkn.de/page/raki\\]\\|test | foo\\]bar]")
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("http://github.com/ydkn/raki")
    assert_equal '<a target="_blank" href="javascript:alert(\'document.cockie\')">xss</a>', parse("[javascript:alert('document.cockie')|xss]")
    assert_equal '<a href="mailto:rakitest@spam.f0i.de">mail</a>', parse("[mailto:rakitest@spam.f0i.de|mail]")
  end

  # Test for bold text
  def test_bold_text
    assert_equal "<b>some text</b><br/><b>some other text</b>", parse("*some text*\n*some other text*")
    assert_equal '<b>some text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a> some other</b> text', parse("*some text [WikiPageName] some other* text")
  end

  # Test for bold text
  def test_strikedthrough_text
    assert_equal "<del>some text</del><br/><del>some other text</del>", parse("-some text-\n-some other text-")
    assert_equal '<del>some text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a> some other</del> text', parse("-some text [WikiPageName] some other- text")
  end

  # Test for italic text
  def test_italic_text
    assert_equal "<i>test</i>", parse("~test~")
    assert_equal "<i>some text</i><br/><i>some other text</i>", parse("~some text~\n~some other text~")
    assert_equal '<i>some text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a> some other text</i>', parse("~some text [WikiPageName] some other text~")
  end

  # Test for bold text
  def test_underlined_text
    assert_equal '<span class="underline">some text</span>', parse("_some text_")
    assert_equal '<span class="underline">some text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a> some other</span> text', parse("_some text [WikiPageName] some other_ text")
    assert_equal '<span class="underline">some text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a></span> text', parse("_some text [WikiPageName]_ text")
  end

  # Test for mixed formating
  def test_mixed_formating
    assert_equal '<span class="underline"><b>some text</b></span>', parse("_*some text*_")
    assert_equal '<span class="underline">test <b>some text</b></span>', parse("_test *some text*_")
    assert_equal '<span class="underline">test<b>some text</b></span>', parse("_test*some text*_")
    assert_equal '<span class="underline">test <i>some text</i></span>', parse("_test ~some text~_")
    assert_equal '<i>test <b><span class="underline">some text</span></b></i>', parse("~test *_some text_*~")
    assert_equal '<i><b>test</b> some text</i>', parse("~*test* some text~")
    assert_equal '<i><b>test</b> some <span class="underline">text</span></i>', parse("~*test* some _text_~")
    assert_equal '<span class="underline"><b>some</b> text <a href="/test/WikiPageName" title="WikiPageName">WikiPageName</a> some <i>other</i></span> text', parse("_*some* text [WikiPageName] some ~other~_ text")
  end

  # Test for headings
  def test_headings
    assert_equal "<h1 id=\"section-Heading_first_order\">Heading first order</h1>", parse("!Heading first order")
    assert_equal "<h1 id=\"section-Heading_first_order\">Heading first order</h1><br/>", parse("!Heading first order\r\n\r\n\r\n")
    assert_equal "<h2 id=\"section-Heading_second_order\">Heading second order</h2>", parse("!!Heading second order\n")
    assert_equal "<h3 id=\"section-Heading_third_order\">Heading third order</h3>", parse("!!!Heading third order")
    assert_equal "<h6 id=\"section-Heading_sixth_order\">Heading sixth order</h6>", parse("!!!!!!Heading sixth order\n")
    assert_equal "<h6 id=\"section-Heading_sixth_order_with_extra_exclamation_marks\">!!Heading sixth order with extra exclamation marks</h6>", parse("!!!!!! !!Heading sixth order with extra exclamation marks\n")
    assert_equal "<h1 id=\"section-Heading_first_order\">Heading first order</h1>test", parse("!Heading first order\ntest")
    assert_equal "<h1 id=\"section-Heading_first__order_\"><i>Heading first</i> <span class=\"underline\">order</span></h1>test", parse("!~Heading first~ _order_\ntest")
    assert_equal "<h1 id=\"section-Heading_first_Link_order\">Heading first <a class=\"inexistent\" href=\"/test/Link\" title=\"Link\">Link</a> order</h1>test", parse("!Heading first [Link] order\ntest")
    # assert_equal "<h1 id=\"Heading_first_order\">Heading first <span class=notbold>order</span></h1>\ntest", parse("!Heading first *order*\ntest")
  end

  # Test for message boxes
  def test_messagebox
    assert_equal '<div class="information">content of info-box</div>', parse("%%information content of info-box%%")
    assert_equal '<div class="error">content of error-box</div>', parse("%%error content of error-box%%")
    assert_equal '<div class="warning">content of warning-box</div>', parse("%%warning content of warning-box%%")
    assert_equal '<div class="confirmation">content of confirmation-box</div>', parse("%%confirmation content of confirmation-box%%")
    assert_equal '<div class="confirmation"><a class="inexistent" href="/test/content" title="content">content</a> of confirmation-box</div>', parse("%%confirmation [content] of confirmation-box%%")
    assert_equal '<div class="error"><div class="warning">some warning</div></div>', parse("%%error %%warning some warning%%%%")
    assert_equal '<div class="error">error<div class="warning">some warning</div></div>', parse("%%error error%%warning some warning%%%%")
    assert_equal '<div class="error"><div class="warning">some warning</div> test</div>', parse("%%error %%warning some warning%% test%%")
    assert_equal '<div class="error">error! <div class="warning">some warning</div> test</div>', parse("%%error error! %%warning some warning%% test%%")
    assert_equal '<div class="warning"><b>content</b> of confirmation-box</div>', parse("%%warning *content* of confirmation-box%%")
    assert_equal "<div class=\"warning\"><b>content</b><br/><ul><li>of</li><li>confirmation-box</li></ul><br/></div>", parse("%%warning *content*\n* of\n* confirmation-box\n%%")
    assert_equal "<div class=\"warning\"><h1 id=\"section-content\">content</h1>of confirmation-box</div>", parse("%%warning !content\nof confirmation-box%%")
    assert_equal "<div class=\"warning\"><h1 id=\"section-content\">content</h1></div>", parse("%%warning !content%%")
  end

  # Test for unordered lists
  def test_unordered_lists
    assert_equal "<ul><li>test</li></ul>", parse("* test")
    assert_equal "<ul><li>foo<br/> bar</li></ul>", parse("* foo\r\n bar")
    assert_equal "<ul><li>test</li><li>test</li></ul>", parse("* test\n* test")
    assert_equal "<ul><li>abc</li><li>def</li><li>ghi</li><li>jkl</li></ul>", parse("\n* abc\n* def\n* ghi\n* jkl")
    assert_equal "<ul><li><a href=\"/test/WikiPageName\" title=\"WikiPageName\">WikiPageName</a></li></ul>", parse("\n* [WikiPageName]")
    assert_equal "<ul><li>asdf<br/> asdf\n<ul><li>asdf<br/> asdf</li><li>asdf<br/> asdf</li></ul></li><li>asdf</li></ul>", parse("* asdf\n asdf\n * asdf\n asdf\n * asdf\n asdf\n* asdf")
  end

  # Test for ordered lists
  def test_ordered_lists
    assert_equal "<ol><li>abc</li><li>def</li><li>ghi</li><li>jkl</li></ol>", parse("\n# abc\n# def\n# ghi\n# jkl")
    assert_equal "<ol><li>abc</li><li>def</li><li>ghi<br/> test</li><li>jkl</li></ol>", parse("\n# abc\n# def\n# ghi\n test\n# jkl")
    assert_equal "<ol><li><a href=\"/test/WikiPageName\" title=\"WikiPageName\">WikiPageName</a></li></ol>", parse("\n# [WikiPageName]")
  end

  def test_mixed_lists
    assert_equal "<ul><li>item1</li></ul><ol><li>item2</li></ol>", parse("* item1\n# item2")
    assert_equal "<ul><li>item1\n<ol><li>item2</li></ol></li></ul>", parse("* item1\n # item2")
    assert_equal "<ul><li>item1\n<ol><li>item2</li></ol></li><li>item3</li></ul>", parse("* item1\n # item2\n* item3")
    assert_equal "<ol><li>hello</li><li>world\n<ul><li>sub</li><li>bla</li></ul><ol><li>test\n<ul><li>foo</li></ul></li></ol></li><li>bar</li></ol>",
        parse("# hello\n# world\n * sub\n * bla\n # test\n  * foo\n# bar")
  end

  def test_table
    assert_equal "<table class=\"wikitable\"><tr><td>test</td><td>asdf</td></tr><tr><td>foo</td><td>bar</td></tr></table>", parse("|test|asdf|\n|foo|bar|")
    assert_equal "<table class=\"wikitable\"><tr><th>test</th><th>asdf</th></tr><tr><td>foo</td><td>bar</td></tr></table>", parse("!|test|asdf|\n|foo|bar|")
    assert_equal "<table class=\"wikitable\"><tr><th>test</th><th>asdf</th></tr><tr><td><b>foo</b></td><td><i>bar</i></td></tr></table>", parse("!|test|asdf|\n|*foo*|~bar~|")
    assert_equal "<table class=\"wikitable\"><tr><th>test</th><th>asdf</th></tr><tr><td>*foo*asdf</td><td><i>bar</i></td></tr></table>", parse("!|test|asdf|\n|*foo*asdf|~bar~|")
    assert_equal "<table class=\"wikitable\"><tr><th>test</th><th>asdf</th></tr><tr><td>*foo*asdf</td><td><i>bar</i> asdf</td></tr></table>", parse("!|test|asdf|\n|*foo*asdf|~bar~ asdf|")
  end

  def test_pages
    assert_equal "<a href=\"/test/link\" title=\"link\">link</a><br/><ul><li>item1</li></ul><ol><li>item2</li></ol>", parse("[link]\n\n* item1\n# item2")
    assert_equal "<h1 id=\"section-Testseite\">Testseite</h1><a href=\"/test/link\" title=\"link\">link</a><br/><ul><li><b>item1</b></li></ul><ol><li>item2</li></ol>", parse("!Testseite\n\n[link]\n\n* *item1*\n# item2")
  end

  # Test rewriting of links
  def test_link_update
    old_page = Page.new(:namespace => 'test', :name => 'OldPage')
    new_page = Page.new(:namespace => 'test', :name => 'NewPageName')
    other_page = Page.new(:namespace => 'test', :name => 'OtherPage')
    
    assert_equal [true, '[NewPageName]'], link_update("[OldPage]", old_page, new_page)
    assert_equal [false, '[OldPage]'], link_update("[OldPage]", other_page, new_page)
    assert_equal [true, 'some text [NewPageName] some other text'], link_update("some text [OldPage] some other text", old_page, new_page)
    assert_equal [false, "foo [other link] *bar*\ntest"], link_update("foo [other link] *bar*\ntest", old_page, new_page)
    assert_equal [true, "foo [other link] *bar*\n[NewPageName] test"], link_update("foo [other link] *bar*\n[OldPage] test", old_page, new_page)
  end
  
  # Test gathering of chapters
  def test_sections
    assert_equal [
      {:anchor => 'section-Heading1', :title => 'Heading1', :subsections => [
          {:anchor => 'section-Heading2', :title => 'Heading2', :subsections => []}
        ]
      }
    ], sections("!Heading1\n!!Heading2")
    
    assert_equal [
      {:anchor => 'section-Heading1', :title => 'Heading1', :subsections => [
          {:anchor => 'section-Heading2', :title => 'Heading2', :subsections => []},
          {:anchor => 'section-Heading3', :title => 'Heading3', :subsections => []}
        ]
      },
      {:anchor => 'section-Heading4', :title => 'Heading4', :subsections => []},
    ], sections("!Heading1\n!!Heading2\n!!Heading3\n!Heading4")
  end

  def test_plugin
    Raki::Plugin.register :testexample do
      execute do
        render :inline => body.reverse
      end
    end
    assert_equal "fdsa", parse("\\testexample asdf\\")
    assert_equal "fdsa<br/>foo\\ bar", parse("\\testexample asdf\\\r\nfoo\\ bar")
    assert_equal "tset \nfdsa", parse("\\testexample asdf\n test\\end")
    assert_equal "", parse("\\testexample\\")

    Raki::Plugin.register :testparams do
      execute do
        render :inline => params[:name] + params[:id]
      end
    end
    assert_equal 'hello world', parse('\\testparams id=world name="hello "\\')
    assert_equal 'helloworld', parse('\\testparams id=world name="hello"\\')
  end

  private

  # Shortener for the parse method
  def parse text, context=@context
    @parser.parse text, context
  end
  
  def link_update text, from, to
    @parser.link_update text, from, to, @context
  end
  
  def sections text, context=@context
    @parser.sections text, context
  end

  # Creates a user
  def user username, email
    User.new(Time.new.to_s, :username => username, :email => email)
  end

  # Default user
  def default_user
    @default_user ||= user('raki_parser_test', 'test@user.org')
  end

end
