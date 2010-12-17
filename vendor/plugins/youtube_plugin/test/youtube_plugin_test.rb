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

require 'raki_plugin_test'

class YoutubePluginTest < Raki::Test::Plugin::TestCase
  
  def test_no_video
    assert_raise_plugin_error 'No video specified' do
      exec({}, '')
    end
  end
  
  def test_url
    ['-dnL00TdmLY', 'DWef69ItVrU'].each do |vid|
      assert_equal embed_code(vid), exec({}, "http://www.youtube.com/watch?v=#{vid}")
    end
  end
  
  def test_embed_url
    ['-dnL00TdmLY', 'DWef69ItVrU'].each do |vid|
      assert_equal embed_code(vid), exec({}, "http://www.youtube.com/embed/#{vid}")
    end
  end
  
  private
  
  def embed_code(video_id)
    "<iframe title=\"YouTube video player\" class=\"youtube-player\" type=\"text/html\" width=\"640\" height=\"385\" src=\"http://www.youtube.com/embed/#{video_id}\" frameborder=\"0\"></iframe>"
  end
  
end
