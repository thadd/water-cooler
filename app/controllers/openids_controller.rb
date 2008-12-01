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

require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'

# Provides a contoller for authenticating OpenID users.
class OpenidsController < ApplicationController
  skip_before_filter :check_logged_in

  # Make sure OpenID is enabled
  before_filter :check_openid_enabled

  # Starts the login process.
  def create
    # Get the user's OpenID URL
    openid_url = params[:openid_url]

    # Check for allowed
    unless AppConfig.openid_allowed_urls.nil?
      unless AppConfig.openid_allowed_urls.include?(OpenID::normalize_url(openid_url))
        flash[:notice] = "OpenID URL entered is not in the allowed list"
        redirect_to new_participant_url
        return
      end
    end

    # Check for banned
    unless AppConfig.openid_banned_urls.nil?
      if AppConfig.openid_banned_urls.include?(OpenID::normalize_url(openid_url))
        flash[:notice] = "OpenID URL is on the banned list"
        redirect_to new_participant_url
        return
      end
    end

    # Catch errors
    begin
      # Create the request. This will throw an error if there's no OpenID at
      # the specified URL.
      oid_request = openid_consumer.begin(openid_url)

      # Set up the SREG request for the user's timezone and their nickname.
      sreg_request = OpenID::SReg::Request.new
      sreg_request.request_fields(['timezone', 'nickname'], false)

      # Add the extension request
      oid_request.add_extension(sreg_request)
      oid_request.return_to_args['did_sreg'] = 'y'

      # Send the user to their OpenID URL
      redirect_to oid_request.redirect_url(root_url, complete_openid_url)
    rescue OpenID::DiscoveryFailure
      # No OpenID there, notify
      flash[:notice] = "Couldn't find an OpenID for that URL"
      redirect_to new_participant_url
    end
  end

  # Second part of the login process. The OpenID provider will redirect here
  # after attempting to log the user in.
  def complete
    # The OpenID system bails on the unknown action and controller parameters
    # that Rails adds to the return URL, so we need to remove them.
    openid_params = params.delete_if do |key,value|
      key == "action" || key == "controller"
    end

    # Have the OpenID subsystem finish the login
    response = openid_consumer.complete(openid_params,complete_openid_url)

    # If the login was successful
    if response.status == OpenID::Consumer::SUCCESS
      # Get the extension response
      reg_info = response.extension_response(OpenID::SReg::NS_URI, false)

      # Add sym keys for later consistency
      reg_info.each {|key,value| reg_info[key.to_sym] = value}

      # Default the timezone to UTC.
      session[:time_zone] = 0

      # If the user's OpenID provider supplies a timezone
      if reg_info[:timezone]
        # Get the timezone
        Time.zone = reg_info[:timezone]

        # Store it in the session for later use
        session[:time_zone] = Time.zone.utc_offset
      end

      # Check to see if this person has ever logged in before
      unless @participant = Participant.find_by_username(response.identity_url)
        # Create the user
        @participant = Participant.new(:username => response.identity_url)

        # Set the user's name to their nickname, or OpenID URL
        @participant.name = reg_info[:nickname] || response.identity_url
      end

      # User will not be away after logging in
      @participant.active = ''

      # Determine admin status
      @participant.admin = AppConfig.openid_admins &&
        AppConfig.openid_admins.collect{|admin|OpenID::normalize_url(admin)}.include?(response.identity_url)

      # Check to see if this was the first time logging in
      participant_was_new = @participant.new_record?

      # Save the user
      if @participant.save
        # Set the session parameter marking them as logged in.
        session[:whoami] = @participant.username

        # If the person was new, create a keyword for their name
        if participant_was_new
          Keyword.create(:text => @participant.name, :participant => @participant)
        end

        # Notify and send them to the chat room list
        flash[:notice] = 'You have been logged in'
        redirect_to(chat_rooms_url)
      else
        # This shouldn't happen, but it could
        logger.debug(@participant.errors.inspect)
        flash[:notice] = "There was a problem saving to the database"
        redirect_to(new_participant_url)
      end

    else
      # Notify that OpenID login failed
      flash[:notice] = "OpenID login failed (#{response.message})"
      redirect_to new_participant_url
    end
  end

  protected

  # Provides the memoized OpenID consumer using a filesystem store.
  def openid_consumer
    @openid_consumer ||= OpenID::Consumer.new(session, OpenID::Store::Filesystem.new("#{RAILS_ROOT}/tmp/openid"))
  end

  # Checks to make sure that OpenID is enabled in the application settings.
  def check_openid_enabled
    unless AppConfig.use_openid
      flash[:notice] = "OpenID login is not enabled"
      redirect_to new_participant_url
    end
  end
end
