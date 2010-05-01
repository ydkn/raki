# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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
    @parser = RakiParser.new
  end

  def test_text
    assert_equal "\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ", parse("\x60abcdefghijklmnopqrstuvwxyz \tABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end

  # Test linebreaks
  def test_linebreaks
    assert_equal "test<br/>\ntext<br/>\nhallo", parse("test\ntext\n\nhallo")
  end

  # Test links for wikipages
  def test_link_to_page
    assert_equal '<a href="/wiki/WikiPageName">WikiPageName</a>', parse("[WikiPageName]")
    assert_equal '<a href="/wiki/WikiPageName">WikiPageName</a>', parse("[ WikiPageName  ]")
    assert_equal '<a href="/wiki/WikiPageName">title for link</a>', parse("[WikiPageName|title for link]")
  end

  # Test links for urls
  def test_link
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("[http://github.com/ydkn/raki]")
    assert_equal '<a href="http://github.com/ydkn/raki">Raki on github</a>', parse("[http://github.com/ydkn/raki|Raki on github]")
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("http://github.com/ydkn/raki")
  end

  # Test for bold text
  def test_bold_text
    assert_equal "<b>some text</b><br/>\n<b>some other text</b>", parse("**some text**\n**some other text**")
    assert_equal '<b>some text <a href="/wiki/WikiPageName">WikiPageName</a> some other</b> text', parse("**some text [WikiPageName] some other** text")
  end

  # Test for bold text
  def test_strikedthrough_text
    assert_equal "<del>some text</del><br/>\n<del>some other text</del>", parse("--some text--\n--some other text--")
    assert_equal '<del>some text <a href="/wiki/WikiPageName">WikiPageName</a> some other</del> text', parse("--some text [WikiPageName] some other-- text")
  end

  # Test for italic text
  def test_italic_text
    assert_equal "<i>some text</i><br/>\n<i>some other text</i>", parse("''some text''\n''some other text''")
    assert_equal '<i>some text <a href="/wiki/WikiPageName">WikiPageName</a> some other text</i>', parse("''some text [WikiPageName] some other text''")
  end

  # Test for bold text
  def test_underlined_text
    assert_equal '<span class="underline">some text</span>', parse("__some text__")
    assert_equal '<span class="underline">some text <a href="/wiki/WikiPageName">WikiPageName</a> some other</span> text', parse("__some text [WikiPageName] some other__ text")
  end

  # Test for headings
  def test_headings
    assert_equal "<h1>Heading first order</h1>\n", parse("!Heading first order")
    assert_equal "<h2>Heading second order</h2>\n", parse("!!Heading second order\n")
    assert_equal "<h3>Heading third order</h3>\n", parse("!!!Heading third order")
    assert_equal "<h6>Heading sixth order</h6>\n", parse("!!!!!!Heading sixth order\n")
    assert_equal "<h6>!!Heading sixth order with extra exlamation marks</h6>\n", parse("!!!!!! !!Heading sixth order with extra exlamation marks\n")
    assert_equal "<h1>Heading first order</h1>\ntest", parse("!Heading first order\ntest")
  end

  # Test for message boxes
  def test_messagebox
    assert_equal '<div class="information">content of info-box</div>', parse("%%information content of info-box%%")
    assert_equal '<div class="error">content of error-box</div>', parse("%%error content of error-box%%")
    assert_equal '<div class="warning">content of warning-box</div>', parse("%%warning content of warning-box%%")
    assert_equal '<div class="confirmation">content of confirmation-box</div>', parse("%%confirmation content of confirmation-box%%")
  end

  # Test for unordered lists
  def test_unordered_lists
    assert_equal "<ul>\n<li>test</li>\n</ul>\n", parse("* test")
    assert_equal "<ul>\n<li>test</li>\n<li>test</li>\n</ul>\n", @parser.parse("*test\n*test")
    assert_equal "<ul>\n<li>abc</li>\n<li>def</li>\n<li>ghi</li>\n<li>jkl</li>\n</ul>\n", parse("\n*abc\n* def\n*ghi\n* jkl")
    assert_equal "<ul>\n<li><a href=\"/wiki/WikiPageName\">WikiPageName</a></li>\n</ul>\n", parse("\n*[WikiPageName]")
  end

  # Test for ordered lists
  def test_ordered_lists
    assert_equal "<ol>\n<li>abc</li>\n<li>def</li>\n<li>ghi</li>\n<li>jkl</li>\n</ol>\n", parse("\n#abc\n# def\n#ghi\n# jkl")
    assert_equal "<ol>\n<li><a href=\"/wiki/WikiPageName\">WikiPageName</a></li>\n</ol>\n", parse("\n#[WikiPageName]")
  end

  def test_mixed_lists
    assert_equal "<ul>\n<li>item1</li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("*item1\n#item2")
    assert_equal "<ul>\n<li>item1\n<ol>\n<li>item2</li>\n</ol>\n</li>\n</ul>\n", parse("*item1\n #item2")
    assert_equal "<ul>\n<li>item1\n<ol>\n<li>item2</li>\n</ol>\n</li>\n<li>item3</li>\n</ul>\n", parse("*item1\n #item2\n*item3")
    assert_equal "<ol>\n<li>hello</li>\n<li>world\n<ul>\n<li>sub</li>\n<li>bla</li>\n</ul>\n<ol>\n<li>test\n<ul>\n<li>foo</li>\n</ul>\n</li>\n</ol>\n</li>\n<li>bar</li>\n</ol>\n",
        parse("#hello\n#world\n *sub\n * bla\n #test\n  * foo\n#bar")
  end

  def test_pages
    assert_equal "<a href=\"/wiki/link\">link</a><br/>\n<ul>\n<li>item1</li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("[link]\n\n*item1\n#item2")
    assert_equal "<h1>Testseite</h1>\n<a href=\"/wiki/link\">link</a><br/>\n<ul>\n<li><b>item1</b></li>\n</ul>\n<ol>\n<li>item2</li>\n</ol>\n", parse("!Testseite\n\n[link]\n\n* **item1**\n#item2")
  end

  def test_plugin
    Raki::Plugin.register :testexample do
      execute do |params, body, context|
        body.reverse
      end
    end
    assert_equal "fdsa", parse("[{testexample asdf}]")
    assert_equal "tset \nfdsa", parse("[{testexample asdf\n test}]")
    assert_equal "", parse("[{testexample}]")

    Raki::Plugin.register :testparams do
      execute do |params, body, context|
        params[:name] + params[:id]
      end
    end
    assert_equal 'hello world', parse('[{testparams id=world name="hello " }]')
  end

  private

  # Shortener for the parse method
  def parse(text)
    @parser.parse(text)
  end

end
