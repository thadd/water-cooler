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

module ChatRoomsHelper
  def name_classes(chat_room)
    classes = ["room_name"]
    classes << "locked" if chat_room.locked?
    classes << "is_member" if chat_room.is_member?(@whoami)
    classes.join(" ")
  end

  def active?(membership)
    "active" if membership.active?
  end

  def current?(membership)
    "current" if @chat_room == membership.chat_room
  end

  def notification?(membership)
    "notification_waiting" if @chat_rooms_with_notifications.include?(membership.chat_room)
  end

  def delete_room_warning
    "All history and transcripts will be lost. Are you sure you want to delete the room?"
  end

  def member_list_spans(chat_room)
    spans = chat_room.memberships.collect do |membership|
      res = ""
      res += '<span class="active">' if membership.active?
      res += h(membership.participant.name)
      res += "</span>" if membership.active?
      res
    end

    spans.join(", ")
  end
end
