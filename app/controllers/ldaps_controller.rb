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

class LdapsController < ApplicationController
  skip_before_filter :check_logged_in

  def create
    session[:time_zone] = params[:participant_time_zone]
    session[:time_zone] = 0 if session[:time_zone].blank?

    # Check to see if this person has ever logged in before
    unless @participant = Participant.find_by_username(params[:participant][:username])
      @participant = Participant.new(:username => params[:participant][:username])
      @participant.name = params[:participant][:username]
    end

    # User will not be away after logging in
    @participant.active = ''

    # Check to see if this was the first time logging in
    participant_was_new = @participant.new_record?

    # Setup the LDAP connection
    ldap_dn = AppConfig.ldap_user_pre_dn +
      params[:participant][:username] +
      AppConfig.ldap_user_post_dn

    ldap = Net::LDAP.new
    ldap.host = AppConfig.ldap_host
    ldap.port = AppConfig.ldap_port
    ldap.auth ldap_dn, params[:participant][:password]

    begin
      if ldap.bind
        ldap.search({:base => AppConfig.ldap_admin_group_dn, :filter => AppConfig.ldap_admin_group_type}) do |entry|
          @participant.admin = entry[AppConfig.ldap_admin_group_field].include?(@participant.username)
        end
      else
        raise Net::LDAP::LdapError.new("Login failed")
      end
    rescue Net::LDAP::LdapError
      flash[:notice] = "Error: #{$!.message}"
      redirect_to new_participant_url
      return
    end

    if @participant.save
      session[:whoami] = @participant.username

      if participant_was_new
        Keyword.create(:text => @participant.name, :participant => @participant)
      end

      flash[:notice] = 'You have been logged in'
      redirect_to(chat_rooms_url)
    else
      flash[:notice] = 'There was a problem saving to the database'
      redirect_to(new_participant_url)
    end
  end
end
