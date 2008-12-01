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

# Controller for showing transcripts of a chat room. The transcript provides a
# full history of the conversations in a room. If the room is locked, or was
# locked when it was archived, then this controller will only let people who
# were members of the room at the time it was archived view the history.
class TranscriptsController < ApplicationController
  before_filter :check_for_room_owner, :except => :show

  # Creates a new transcript. This action has the effect of archiving a chat
  # room.
  def create
    # Find the chat room
    chat_room = ChatRoom.find(params[:chat_room])

    # Archive the room
    chat_room.archived = true

    # Save the change
    chat_room.save!

    # Notify
    flash[:notice] = "Archived the chat room"
    redirect_to chat_rooms_url
  end

  # Destroys the chat room. This method is actually non-destructive and has the
  # effect of unarchiving a chat room.
  def destroy
    # Get the room
    chat_room = ChatRoom.find(params[:id])

    # Unarchive the room
    chat_room.archived = false

    # Save the change
    chat_room.save!

    # Notify
    flash[:notice] = "Unarchived the chat room"
    redirect_to chat_rooms_url
  end

  # Dispays the transcript.
  def show
    # Get the room
    @chat_room = ChatRoom.find(params[:id])

    # Get the room's messages
    @messages = @chat_room.messages

    # We won't show any notifications on transcripts
    @messages_with_notifications = []

    # Check to see if the user isn't a member of the room
    unless @chat_room.participants.include?(whoami)
      # If the room isn't locked, let the user join the room
      unless @chat_room.locked?
        Membership.create(:participant => whoami, :chat_room => @chat_room)
      else
        # The room was locked and the user wasn't a member so they can't see
        # the room's transcript
        flash[:notice] = "Chat room is locked, you can't view transcript"
        return redirect_to(chat_rooms_url)
      end
    end
  end

  protected

  # Checks to see if the current user owns the room or is an admin.
  def check_for_room_owner
    unless whoami_owns_room?(ChatRoom.find(params[:id]))
      flash[:notice] = "You do not have permissions to archive this room"
      redirect_to chat_rooms_url
    end
  end
end
