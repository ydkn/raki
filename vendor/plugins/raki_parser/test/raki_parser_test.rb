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

  # Test linebreaks
  def test_linebreaks
    assert_equal "<br/>\n", parse("\n")
    assert_equal "test<br/>\ntext<br/>\nhallo", parse("test\ntext\nhallo")
  end

  # Test links for wikipages
  def test_link_to_page
    assert_equal '<a href="WikiPageName">WikiPageName</a>', parse("[WikiPageName]")
    assert_equal '<a href="WikiPageName">title for link</a>', parse("[WikiPageName|title for link]")
  end

  # Test links for urls
  def test_link
    assert_equal '<a href="http://github.com/ydkn/raki">http://github.com/ydkn/raki</a>', parse("[http://github.com/ydkn/raki]")
    assert_equal '<a href="http://github.com/ydkn/raki">Raki on github</a>', parse("[http://github.com/ydkn/raki|Raki on github]")
  end

  # Test for bold text
  def test_bold_text
    assert_equal '<b>some text</b>', parse("__some text__")
    assert_equal '<b>some text <a href="WikiPageName">WikiPageName</a> some other text</b>', parse("__some text [WikiPageName] some other text__")
  end

  # Test for italic text
  def test_italic_text
    assert_equal '<i>some text</i>', parse("''some text''")
    assert_equal '<i>some text <a href="WikiPageName">WikiPageName</a> some other text</i>', parse("''some text [WikiPageName] some other text''")
  end

  # Test for headings
  def test_headings
    assert_equal '<h1>Heading first order</h1>', parse("!Heading first order")
    assert_equal '<h2>Heading second order</h2>', parse("!!Heading second order")
    assert_equal '<h3>Heading third order</h3>', parse("!!!Heading third order")
    assert_equal '<h6>Heading sixth order</h6>', parse("!!!!!!Heading sixth order")
    assert_equal '<h6>!!Heading sixth order with extra exlamation marks</h6>', parse("!!!!!!!!Heading sixth order with extra exlamation marks")
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
    assert_equal '<ul><li>abc</li><li>def</li><li>ghi</li><li>jkl</li></ul>', parse("*abc\n* def\n*ghi\n* jkl")
    assert_equal '<ul><li><a href="WikiPageName">WikiPageName</a></li></ul>', parse("*[WikiPageName]")
  end

  # Test for ordered lists
  def test_ordered_lists
    assert_equal '<ol><li>abc</li><li>def</li><li>ghi</li><li>jkl</li></ol>', parse("#abc\n# def\n#ghi\n# jkl")
    assert_equal '<ol><li><a href="WikiPageName">WikiPageName</a></li></ol>', parse("#[WikiPageName]")
  end

  private

  # Shortener for the parse method
  def parse(text)
    @parser.parse(text)
  end

end
