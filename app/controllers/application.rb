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

class ApplicationController < ActionController::Base
  helper :all

  protect_from_forgery

  # Keep passwords out of log files
  filter_parameter_logging "password"

  # Make sure they're logged in
  before_filter :check_logged_in

  # Set the time zone
  before_filter :set_time_zone

  # Make some methods available as helpers
  helper_method :whoami
  helper_method :whoami_owns_room?

  private

  # This helps us use this with HTTPS.
  def default_url_options(options = nil)
    {:only_path => true}
  end

  # Checks to make sure the user is logged in.
  def check_logged_in #:doc:
    # Does the @whoami variable get set to something sane?
    unless @whoami ||= whoami
      # Notify
      flash[:notice] = "Please log in"
      redirect_to new_participant_url
    end
  end

  # Gets the currently logged in user.
  def whoami #:doc:
    Participant.find_by_username(session[:whoami])
  end

  # Returns true if the currently logged in user has owner permissions for the
  # specified room.
  def whoami_owns_room?(chat_room) #:doc:
    chat_room.owner == whoami || whoami.admin?
  end

  # Reports whether the notification sounds should play.
  def notification_sounds_enabled? #:doc:
    session[:notification_sounds] != "off"
  end

  # Reports whether the room sounds should play.
  def room_sounds_enabled? #:doc:
    session[:room_sounds] != "off"
  end

  # Sets the time zone based on the user preferences.
  def set_time_zone #:doc:
    Time.zone = ActiveSupport::TimeZone[session[:time_zone].to_i]
  end
end
