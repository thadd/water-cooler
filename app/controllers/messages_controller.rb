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

# Provides a controller for messages. This controller is only ever hit via
# AJAX.
class MessagesController < ApplicationController
  before_filter :get_chat_room
  before_filter :check_for_chat_room_member

  # Gets recent messages and populates the message list.
  def index
    if request.xhr?
      # Evict the user if their membership no longer exists
      if Membership.joining(@whoami, @chat_room).blank?
        flash[:notice] = "You have been evicted from #{@chat_room.name} by the owner or an admin."
        @member_should_be_evicted = true
      end

      # Evict the user if the chat room has been archived
      if @chat_room.archived?
        flash[:notice] = "Chat room is archived"
        @member_should_be_evicted = true
      end

      # Get the highest ID (or -1 if it's not set)
      last_id = params[:last_id].blank? ? -1 : params[:last_id]

      # Get messages newer than the last ID
      @messages = @chat_room.messages.find(:all, :conditions => ['id > ?', last_id])

      # If there are no messages
      if @messages.blank?
        # Get the current highest from the database
        @current_highest_message = @chat_room.messages.maximum(:id)
      else
        # Use the the highest id from the returned array
        @current_highest_message = @messages.last.id
      end

      # Get any notifications currently pending in this room
      notifications_for_this_room = Notification.find(:all, :conditions => ['participant_id = ?',  @whoami])

      # Get any messages that have notifications
      @messages_with_notifications = notifications_for_this_room.collect {|n| n.message}

      # Clear this room's notifications if we're not away
      unless @whoami.away?
        notifications_for_this_room.delete_if do |n|
          n.message.chat_room != @chat_room
        end
        Notification.destroy(notifications_for_this_room)
      end

      # Check for pending notifications
      if @whoami.pending_notification?
        @should_play_notification_sound = true
        @whoami.pending_notification = false
        @whoami.save!
      end
    end
  end

  # Adds a new message
  def create
    @message = Message.new(params[:message])
    @message.content.strip!
    @message.participant = @whoami
    @message.chat_room = @chat_room

    @message.save unless @message.content.blank?
  end

  protected

  # Gets the current chat room
  def get_chat_room
    @chat_room = ChatRoom.find(params[:chat_room_id])
  end

  # Checks to make sure that the current user is a member of the chat room.
  def check_for_chat_room_member
    unless @chat_room.participants.include?(@whoami)
      flash[:notice] = "You are not a member of this chat room"
      redirect_to(chat_rooms_url)
    end
  end
end
