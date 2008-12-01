#--
# Copyright (c) 2008 Thaddeus Selden
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'RedCloth'

module ApplicationHelper
  def notification_sounds_enabled?
    session[:notification_sounds] != "off"
  end

  def room_sounds_enabled?
    session[:room_sounds] != "off"
  end

  def sound_links
    @room_state = room_sounds_enabled? ? "off" : "on"
    @notification_state = notification_sounds_enabled? ? "off" : "on"
    render :partial => '/shared/sound_links'
  end

  def make_textile(text)
    begin
      if AppConfig.link_bugs
        # Split the URL around the %s
        url_parts = AppConfig.bug_url.split("%s")

        # Expand bugs
        text.gsub!(/\b[Bb]ug *\#(\d+)/){|s| %("#{$&}":#{url_parts[0]}#{$1}#{url_parts[1]})}
      end

      if AppConfig.link_revs
        # Split the URL around the %s
        url_parts = AppConfig.rev_url.split("%s")

        # Expand rev numbers
        text.gsub!(/(\b)([rR][eE][vV] ([0-9a-zA-Z]+))/){|s| %(#{$1}"#{$2}":#{url_parts[0]}#{$3}#{url_parts[1]})}
      end

      RedCloth.new(text, [:lite_mode, :filter_html]).to_html
    rescue
      %(<span style="color:red;">[There was a problem with the Textile formatting in this message.]</span>)
    end
  end

  def title_with_chat_room_name
    title = "Water Cooler Chat"
    title += " | #{h(@chat_room.name)}" unless @chat_room.nil? || @chat_room.name.blank?
    title
  end

  def escape_single_quotes(str)
    str.gsub(/[']/, '\\\\\'')
  end
end
