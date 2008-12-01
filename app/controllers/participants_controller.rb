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

# Provides a controller for logging in chat participants.
class ParticipantsController < ApplicationController
  # Don't need to check logins on the login actions
  skip_before_filter :check_logged_in, :only => [:new, :create]

  # Make sure that the current user is the one changing things
  before_filter :check_for_current_user, :only => [:edit, :update]

  # Shows the login page
  def new
    # If they're currently logged in, they're hitting this page to log out so
    # we'll notify and clear the session.
    flash.now[:notice] = "You have been logged out" if session[:whoami]
    session[:whoami] = nil

    @participant = Participant.new
  end

  # Provides an edit page once a user is logged in.
  def edit
    @participant = Participant.find(params[:id])
  end

  # Logs in users with no authentication. This should only be used for testing.
  def create
    # Check to make sure we're in development mode
    if AppConfig.use_dummy_login
      # Check to see if this person has ever logged in before
      unless @participant = Participant.find_by_username(params[:participant][:username])
        @participant = Participant.new(:username => params[:participant][:username])
        @participant.name = params[:participant][:username]
      end

      # User will not be away after logging in
      @participant.active = ''

      # Check to see if this was the first time logging in
      participant_was_new = @participant.new_record?

      # Admin for testing
      @participant.admin = true

      # Add to database
      if @participant.save
        # Mark logged in
        session[:whoami] = @participant.username

        # Add a keyword for new users
        if participant_was_new
          Keyword.create(:text => @participant.name, :participant => @participant)
        end

        # Notify and send to chat room list
        flash[:notice] = 'You have been logged in'
        redirect_to(chat_rooms_url)
      else
        # Notify
        flash[:notice] = 'There was a problem saving to the database'
        redirect_to(new_participant_url)
      end
    else
      # Notify
      flash[:notice] = "Login method unallowed"
      redirect_to new_participant_url
    end
  end

  # Saves changes to a user's information.
  def update
    # Get the user
    @participant = Participant.find(params[:id])

    # Store the old name to compare with
    old_name = @participant.name

    # Save the changes
    if @participant.update_attributes(params[:participant])
      if params[:form_type] == "nickname"
        # If the name changed
        if old_name != @participant.name
          # Update the name keyword
          key = Keyword.find(:first, :conditions => {:participant_id => @participant, :text => old_name})

          # Change the name and save
          if key
            key.text = @participant.name
            key.save!
          end

          # Notify
          flash[:notice] = 'Nickname changed'
        end
      end

      # If this came from the away message form
      if params[:form_type] == "status"
        # If they're changing their away status to available
        if params[:available]
          # Clear the away message (this will make them active in the current
          # room)
          @participant.active = ''
          @participant.save!
        else
          # Mark them away in each chat room
          @participant.memberships.each do |membership|
            membership.active = false
            membership.save
          end
        end
      end

      # This can be hit via AJAX or normal HTML
      respond_to do |format|
        # HTML success sends to chat room list
        format.html { redirect_to(chat_rooms_url) }

        # Update the current page
        format.js
      end
    else
      flash[:notice] = "Failed to save changes"

      # This can be hit via AJAX or normal HTML
      respond_to do |format|
        # HTML failure re-renders the current page
        format.html { render :action => "edit" }

        # Update the current page
        format.js
      end
    end
  end

  protected

  # Ensures that the user receiving the change is the logged in user
  def check_for_current_user
    unless whoami.id.to_i == params[:id].to_i
      flash[:notice] = "Access forbidden"
      redirect_to chat_rooms_url
    end
  end
end
