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

# Provides controller for doing everything related to chat rooms.
class ChatRoomsController < ApplicationController
  before_filter :check_for_room_owner, :only => [:update, :destroy]

  # Lists all the chat rooms.
  def index
    # Get the lists of various chat rooms
    @active_chat_rooms = ChatRoom.active.alpha.find(:all)
    @inactive_chat_rooms = ChatRoom.inactive.alpha.find(:all)

    # Get any pending notifications
    @notifications = Notification.for(whoami)

    # Deactivate all memberships (since we're looking at the list, not a chat room)
    Membership.deactivate_all_for(whoami)
  end

  # Shows an individual chat room.
  def show
    # Try to find it and fail if it doesn't exist
    unless @chat_room = ChatRoom.find_by_id(params[:id])
      flash[:notice] = "Chat room doesn't exist. Maybe the owner deleted it?"
      return redirect_to(chat_rooms_url)
    end

    # If it's archived, redirect them to the transcript URL
    if @chat_room.archived?
      flash[:notice] = "Chat room is archived, loading transcript"
      return redirect_to(transcript_url(@chat_room))
    end

    # Check to see if the user is already a member of the room
    unless @chat_room.participants.include?(whoami)
      # If it's not locked, create a room membership
      unless @chat_room.locked?
        Membership.create(:participant => whoami, :chat_room => @chat_room)
      else
        # Notify that the room is locked and they can't get in
        flash[:notice] = "Chat room is locked, you can't join"
        return redirect_to(chat_rooms_url)
      end
    end

    # Mark the current membership as active and all others as inactive
    if @membership = Membership.joining(whoami, @chat_room).first
      @membership.active = true && !whoami.away?
      @membership.save!
    end

    # Get all the memberships for listing room members
    @memberships = @chat_room.memberships

    # Get messages from the last 3 days for the chat room
    @messages = @chat_room.messages.since(3.days.ago)

    # If there's no recent messages, get last 50
    @messages = @chat_room.messages.limit(50).reverse if @messages.blank?

    # Get the message ID of the last message in the list. This will be used in
    # the AJAX call to get more messages.
    @current_highest_message = @messages.blank? ? -1 : @messages.last.id

    # Get notifications
    @notifications = Notification.for(whoami)

    # Get current user's keywords
    @keywords = whoami.keywords

    # Get 5 rooms around the current one
    @my_memberships = whoami.rooms_around(@chat_room)

    # Get rooms that have notifications waiting
    @chat_rooms_with_notifications = @notifications.collect{|n| n.message.chat_room}.uniq

    # Get messages that have triggered notifications
    @messages_with_notifications = @notifications.collect(&:message)
  end

  # Displays a form for creating a new chat room.
  def new
    # Create a dummy room
    @chat_room = ChatRoom.new
  end

  # Creates a new chat room.
  def create
    # Create the chat room
    @chat_room = whoami.owned_rooms.build(params[:chat_room])

    # Save the chat room
    if @chat_room.save
      flash[:notice] = 'Chat room created'
      redirect_to(@chat_room)
    else
      render :action => "new"
    end
  end

  # Saves changes to a chat room. The only change allowed is lock/unlock.
  def update
    # Get the chat room
    @chat_room = ChatRoom.find(params[:id])

    # Save the changes
    @chat_room.update_attributes(params[:chat_room])

    # Update the flash based on whether we locked or unlocked the room
    if @chat_room.locked?
      flash[:notice] = 'Chat room now locked. No one else can join.'
    else
      flash[:notice] = 'Chat room now unlocked. Anyone can join.'
    end

    # Send the user back to the page they came from
    redirect_to(:back)
  end

  # Deletes a chat room
  def destroy
    @chat_room = ChatRoom.find(params[:id])
    @chat_room.destroy

    flash[:notice] = %(Deleted chat room "#{@chat_room.name}")
    redirect_to(chat_rooms_url)
  end

  protected

  # Checks to see if the current user owns the room or is an admin.
  def check_for_room_owner
    unless whoami_owns_room?(ChatRoom.find(params[:id]))
      flash[:notice] = "You do not have permissions to modify this room"
      redirect_to chat_rooms_url
    end
  end
end
