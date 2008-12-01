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

# Provides a controller for making changes to the session. Any actions that
# modify session variables should be placed in this controller.
class SessionRequestsController < ApplicationController
  # Provides an action for enabling/disabling sound effects.
  def sounds
    if request.xhr? && request.post?
      # Set the room sounds parameter
      session[:room_sounds] = params[:room_sounds] if params[:room_sounds]

      # Set the notification sounds parameter
      session[:notification_sounds] = params[:notification_sounds] if params[:notification_sounds]

      # Set the text for the links
      @room_link_text = "Turn #{room_sounds_enabled? ? "off" : "on"} room sounds"
      @notification_link_text = "Turn #{notification_sounds_enabled? ? "off" : "on"} notification sounds"
    end
  end
end
