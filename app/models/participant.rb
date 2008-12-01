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

class Participant < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy, :order => 'chat_rooms.name', :include => :chat_room
  has_many :chat_rooms, :through => :memberships, :order => 'chat_room.created_at DESC'
  has_many :notifications, :dependent => :destroy
  has_many :owned_rooms, :class_name => 'ChatRoom', :foreign_key => 'owner_id'
  has_many :pending_messages, :through => :pending_messages, :source => :message, :order => 'message.created_at DESC'
  has_many :keywords, :dependent => :destroy

  validates_length_of :name, :minimum => 3
  validates_uniqueness_of :name, :case_sensitive => false

  before_validation_on_create :check_for_duplicate_name

  # Determines whether the current user is active or not.
  def away?
    ! self.active.blank?
  end

  # Checks for a duplicate name and adds digits unti the name is unique.
  def check_for_duplicate_name
    # See if there are any of this name in the database
    unless Participant.find(:all, :conditions => ['LOWER(name) = ?', self.name.downcase]).blank?
      # If we've already added a digit to the end
      if self.name =~ /\b[0-9]+$/
        self.name.gsub!(/[0-9]+$/) do |digit|
          digit.to_i + 1
        end
      else
        # Add a digit to the end
        self.name += " 1"
      end

      # Check again
      check_for_duplicate_name
    end
  end

  # Gets 5 rooms in alphabetical order with the supplied room in the middle.
  def rooms_around(room)
    # Get the person's rooms in alphabetical order
    rooms = memberships.unarchived.alpha

    # If there are 5 or fewer we don't need to do anything fancy
    return rooms if rooms.length <= 5

    # Get the index for the current room
    room_idx = rooms.index(Membership.joining(self,room).first)

    # By default, show two rooms on either side
    lower = room_idx-2 < 0 ? 0 : room_idx-2
    upper = room_idx+2 > rooms.length-1 ? rooms.length-1 : room_idx+2

    # If this room is near the bottom of the list, fill in from the top
    if lower < 2
      upper += 2-lower
      rooms = rooms[lower..upper][0,5]

    # If this room is near the top of the list, fill in from the bottom
    elsif rooms.length-upper < 2
      lower -= rooms.length-upper+1
      logger.debug("__NOW__ LENGTH: #{rooms.length}, LOWER: #{lower}, UPPER: #{upper}, IDX: #{room_idx}")
      rooms = rooms[lower..upper][-5,5]

    # No need to fill, just show that subset
    else
      rooms = rooms[lower..upper]
    end

    rooms
  end
end
