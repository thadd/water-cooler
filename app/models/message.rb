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

class Message < ActiveRecord::Base
  belongs_to :chat_room
  belongs_to :participant
  has_many :notifications, :dependent => :destroy

  validates_length_of :content, :minimum => 1

  after_save :notify_participants

  named_scope :limit, lambda {|msgs|
    {:limit => msgs, :order => 'id DESC'}
  }
  named_scope :since, lambda {|time|
    {:conditions => ['created_at > ?', time]}
  }

  def notify_participants
    self.chat_room.participants.each do |participant|
      # See if it matches a keyword for any of the participants
      participant.keywords.each do |keyword|
        # Check for author match
        if keyword.text =~ /^from:/
          if self.participant.name.downcase.match(keyword.text[5..-1].downcase)
            Notification.create(:message => self,
                                :participant => participant,
                                :keyword => keyword)
            participant.pending_notification = true
            participant.save!
          end
        elsif self.content.downcase.match(keyword.text.downcase)
          Notification.create(:message => self,
                              :participant => participant,
                              :keyword => keyword)
          participant.pending_notification = true
          participant.save!
        end
      end
    end
  end

  def date
    self.created_at.strftime("%A, %d %b %Y")
  end
end
