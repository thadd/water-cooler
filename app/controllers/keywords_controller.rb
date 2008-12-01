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

# Provides a controller for adding and removing keywords. This controller is
# only ever hit via AJAX reuests.
class KeywordsController < ApplicationController
  # Adds a new keyword for the currently logged in user.
  def create
    if request.xhr?
      # Add the new keyword for the current user
      @keyword = whoami.keywords.create(params[:keyword])

      # Nil it out if it's invalid (errors aren't reported)
      @keyword = nil unless @keyword.valid?
    end
  end

  # Deletes a keyword
  def destroy
    if request.xhr?
      @keyword = Keyword.find(params[:id])
      @keyword.destroy
    end
  end
end
