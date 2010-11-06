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

class RakiParserTest < Test::Unit::TestCase

  # Initializes the parser
  def setup
    @parser = RakiParser.new if @parser.nil?
    @context = {:type => 'test', :page => 'unit'}
  end

  def test_text
    assert_equal '', parse('')
    assert_equal "\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ", parse("\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end

  # Test linebreaks
  def test_linebreaks
    assert_equal "test<br/>\ntext<br/>\nhallo", parse("test\ntext\n\nhallo")
    assert_equal "test<br/>\ntext<br/>\nhallo", parse("test\r\ntext\r\n\r\nhallo")
    assert_equal "test<br/>\ntext<br/>\n<br/>\nhallo", parse("test\ntext\n\n\nhallo")
    assert_equal "test\ntext<br/>\nhallo", parse("test\\\ntext\n\nhallo")
  end

  def test_hline
    assert_equal "\n<hr/>\n", parse("----")
    assert_equal "test\n<hr/>\ntext", parse("test\n----\ntext")
  end

  # Test links for wikipages
  def test_link_to_page
    assert_equal '<a href="/test/WikiPageName">WikiPageName</a>', parse("[WikiPageName]")
    assert_equal '<a href="/test/WikiPageName">WikiPageName</a>', parse("[ WikiPageName  ]")
    assert_equal '<a href="/test/WikiPageName">title for link</a>', parse("[WikiPageName|title for link]")
    assert_equal '<a href="/wiki/WikiPageName">wiki/WikiPageName</a>', parse("[wiki/WikiPageName]")
    assert_equal '<a href="/wiki/WikiPageName">wiki/WikiPageName</a>', parse("[ wiki/WikiPageName  ]")
    assert_equal '<a href="/wiki/WikiPageName">title for link</a>', parse("[wiki/WikiPageName|title for link]")
  end

  # Test links for urls
  def test_link
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("[http://github.com/ydkn/raki]")
    assert_equal '<a href="http://github.com/ydkn/raki">Raki on github</a>', parse("[http://github.com/ydkn/raki|Raki on github]")
    assert_equal '<a href="http://raki.ydkn.de/page/raki]|test">foo]bar</a>', parse("[http://raki.ydkn.de/page/raki\\]\\|test | foo\\]bar]")
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("http://github.com/ydkn/raki")
    assert_equal '<a target="_blank" href="javascript:alert(\'document.cockie\')">xss</a>', parse("[javascript:alert('document.cockie')|xss]")
    assert_equal '<a href="mailto:rakitest@spam.f0i.de">mail</a>', parse("[mailto:rakitest@spam.f0i.de|mail]")
  end

  # Test for bold text
  def test_bold_text
    assert_equal "<b>some text</b><br/>\n<b>some other text</b>", parse("*some text*\n*some other text*")
    assert_equal '<b>some text <a href="/test/WikiPageName">WikiPageName</a> some other</b> text', parse("*some text [WikiPageName] some other* text")
  end

  # Test for bold text
  def test_strikedthrough_text
    assert_equal "<del>some text</del><br/>\n<del>some other text</del>", parse("-some text-\n-some other text-")
    assert_equal '<del>some text <a href="/test/WikiPageName">WikiPageName</a> some other</del> text', parse("-some text [WikiPageName] some other- text")
  end

  # Test for italic text
  def test_italic_text
    assert_equal "<i>test</i>", parse("~test~")
    assert_equal "<i>some text</i><br/>\n<i>some other text</i>", parse("~some text~\n~some other text~")
    assert_equal '<i>some text <a href="/test/WikiPageName">WikiPageName</a> some other text</i>', parse("~some text [WikiPageName] some other text~")
  end

  # Test for bold text
  def test_underlined_text
    assert_equal '<span class="underline">some text</span>', parse("_some text_")
    assert_equal '<span class="underline">some text <a href="/test/WikiPageName">WikiPageName</a> some other</span> text', parse("_some text [WikiPageName] some other_ text")
    assert_equal '<span class="underline">some text <a href="/test/WikiPageName">WikiPageName</a></span> text', parse("_some text [WikiPageName]_ text")
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
    assert_equal '<span class="underline"><b>some</b> text <a href="/test/WikiPageName">WikiPageName</a> some <i>other</i></span> text', parse("_*some* text [WikiPageName] some ~other~_ text")
  end

  # Test for headings
  def test_headings
    assert_equal "<h1>Heading first order</h1>\n", parse("!Heading first order")
    assert_equal "<h1>Heading first order</h1>\n<br/>\n", parse("!Heading first order\r\n\r\n\r\n")
    assert_equal "<h2>Heading second order</h2>\n", parse("!!Heading second order\n")
    assert_equal "<h3>Heading third order</h3>\n", parse("!!!Heading third order")
    assert_equal "<h6>Heading sixth order</h6>\n", parse("!!!!!!Heading sixth order\n")
    assert_equal "<h6>!!Heading sixth order with extra exlamation marks</h6>\n", parse("!!!!!! !!Heading sixth order with extra exlamation marks\n")
    assert_equal "<h1>Heading first order</h1>\ntest", parse("!Heading first order\ntest")
    assert_equal "<h1><i>Heading first</i> <span class=\"underline\">order</span></h1>\ntest", parse("!~Heading first~ _order_\ntest")
    assert_equal "<h1>Heading first <a href=\"/test/Link\">Link</a> order</h1>\ntest", parse("!Heading first [Link] order\ntest")
    # assert_equal "<h1>Heading first <span class=notbold>order</span></h1>\ntest", parse("!Heading first *order*\ntest")
  end

  # Test for message boxes
  def test_messagebox
    assert_equal '<div class="information">content of info-box</div>', parse("%%information content of info-box%%")
    assert_equal '<div class="error">content of error-box</div>', parse("%%error content of error-box%%")
    assert_equal '<div class="warning">content of warning-box</div>', parse("%%warning content of warning-box%%")
    assert_equal '<div class="confirmation">content of confirmation-box</div>', parse("%%confirmation content of confirmation-box%%")
    assert_equal '<div class="confirmation"><a href="/test/content">content</a> of confirmation-box</div>', parse("%%confirmation [content] of confirmation-box%%")
    assert_equal '<div class="error"><div class="warning">some warning</div></div>', parse("%%error %%warning some warning%%%%")
    assert_equal '<div class="error">error<div class="warning">some warning</div></div>', parse("%%error error%%warning some warning%%%%")
    assert_equal '<div class="error"><div class="warning">some warning</div> test</div>', parse("%%error %%warning some warning%% test%%")
    assert_equal '<div class="error">error! <div class="warning">some warning</div> test</div>', parse("%%error error! %%warning some warning%% test%%")
    assert_equal '<div class="warning"><b>content</b> of confirmation-box</div>', parse("%%warning *content* of confirmation-box%%")
    assert_equal "<div class=\"warning\"><b>content</b><br/>\n<ul>\n<li>of</li>\n<li>confirmation-box</li>\n</ul>\n<br/></div>", parse("%%warning *content*\n* of\n* confirmation-box\n%%")
    assert_equal "<div class=\"warning\"><h1>content</h1>\nof confirmation-box</div>", parse("%%warning !content\nof confirmation-box%%")
    assert_equal "<div class=\"warning\"><h1>content</h1></div>", parse("%%warning !content%%")
  end

  # Test for unordered lists
  def test_unordered_lists
    assert_equal "<ul>\n<li>test</li>\n</ul>\n", parse("* test")
    assert_equal "<ul>\n<li>foo<br/>\n bar</li>\n</ul>\n", parse("* foo\r\n bar")
    assert_equal "<ul>\n<li>test</li>\n<li>test</li>\n</ul>\n", parse("* test\n* test")
    assert_equal "<ul>\n<li>abc</li>\n<li>def</li>\n<li>ghi</li>\n<li>jkl</li>\n</ul>\n", parse("\n* abc\n* def\n* ghi\n* jkl")
    assert_equal "<ul>\n<li><a href=\"/test/WikiPageName\">WikiPageName</a></li>\n</ul>\n", parse("\n* [WikiPageName]")
    assert_equal "<ul>\n<li>asdf<br/>\n asdf\n<ul>\n<li>asdf<br/>\n asdf</li>\n<li>asdf<br/>\n asdf</li>\n</ul>\n</li>\n<li>asdf</li>\n</ul>\n", parse("* asdf\n asdf\n * asdf\n asdf\n * asdf\n asdf\n* asdf")
  end

  # Test for ordered lists
  def test_ordered_lists
    assert_equal "<ol>\n<li>abc</li>\n<li>def</li>\n<li>ghi</li>\n<li>jkl</li>\n</ol>\n", parse("\n# abc\n# def\n# ghi\n# jkl")
    assert_equal "<ol>\n<li>abc</li>\n<li>def</li>\n<li>ghi<br/>\n test</li>\n<li>jkl</li>\n</ol>\n", parse("\n# abc\n# def\n# ghi\n test\n# jkl")
    assert_equal "<ol>\n<li><a href=\"/test/WikiPageName\">WikiPageName</a></li>\n</ol>\n", parse("\n# [WikiPageName]")
  end

  def test_mixed_lists
    assert_equal "<ul>\n<li>item1</li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("* item1\n# item2")
    assert_equal "<ul>\n<li>item1\n<ol>\n<li>item2</li>\n</ol>\n</li>\n</ul>\n", parse("* item1\n # item2")
    assert_equal "<ul>\n<li>item1\n<ol>\n<li>item2</li>\n</ol>\n</li>\n<li>item3</li>\n</ul>\n", parse("* item1\n # item2\n* item3")
    assert_equal "<ol>\n<li>hello</li>\n<li>world\n<ul>\n<li>sub</li>\n<li>bla</li>\n</ul>\n<ol>\n<li>test\n<ul>\n<li>foo</li>\n</ul>\n</li>\n</ol>\n</li>\n<li>bar</li>\n</ol>\n",
        parse("# hello\n# world\n * sub\n * bla\n # test\n  * foo\n# bar")
  end

  def test_table
    assert_equal "<table class=\"wikitable\">\n<tr><td>test</td>\n<td>asdf</td>\n</tr>\n<tr><td>foo</td>\n<td>bar</td>\n</tr>\n</table>\n", parse("|test|asdf|\n|foo|bar|")
    assert_equal "<table class=\"wikitable\">\n<tr><th>test</th>\n<th>asdf</th>\n</tr>\n<tr><td>foo</td>\n<td>bar</td>\n</tr>\n</table>\n", parse("!|test|asdf|\n|foo|bar|")
    assert_equal "<table class=\"wikitable\">\n<tr><th>test</th>\n<th>asdf</th>\n</tr>\n<tr><td><b>foo</b></td>\n<td><i>bar</i></td>\n</tr>\n</table>\n", parse("!|test|asdf|\n|*foo*|~bar~|")
  end

  def test_pages
    assert_equal "<a href=\"/test/link\">link</a><br/>\n<ul>\n<li>item1</li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("[link]\n\n* item1\n# item2")
    assert_equal "<h1>Testseite</h1>\n<a href=\"/test/link\">link</a><br/>\n<ul>\n<li><b>item1</b></li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("!Testseite\n\n[link]\n\n* *item1*\n# item2")
  end

  # Test for convertions
  def test_convert
    assert_equal '[NewPageName]', link_update("[OldPage]", "OldPage", 'NewPageName')
    #assert_equal "\\signature user=raki date=10-11-04 time=11:41:28\\", convert('~~~')
  end

  def test_plugin
    Raki::Plugin.register :testexample do
      execute do
        body.reverse
      end
    end
    assert_equal "fdsa", parse("\\testexample asdf\\")
    assert_equal "fdsa<br/>\nfoo\\ bar", parse("\\testexample asdf\\\r\nfoo\\ bar")
    assert_equal "tset \nfdsa", parse("\\testexample asdf\n test\\end")
    assert_equal "", parse("\\testexample\\")

    Raki::Plugin.register :testparams do
      execute do
        params[:name] + params[:id]
      end
    end
    assert_equal 'hello world', parse('\\testparams id=world name="hello "\\')
    assert_equal 'helloworld', parse('\\testparams id=world name="hello"\\')
  end

  private

  # Shortener for the parse method
  def parse text
    @parser.parse(text, @context)
  end
  
  def link_update text, from, to
    @parser.link_update(text, from, to, @context)
  end

end
