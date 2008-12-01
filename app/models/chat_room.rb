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

class ChatRoom < ActiveRecord::Base
  has_many :messages, :dependent => :destroy
  has_many :memberships, :dependent => :destroy, :order => 'participants.name', :include => :participant
  has_many :participants, :through => :memberships
  belongs_to :owner, :class_name => 'Participant'

  named_scope :alpha, :order => 'name ASC'

  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :name, :minimum => 1

  named_scope :inactive, :conditions => {:archived => true}
  named_scope :active, :conditions => {:archived => false}

  # Determines whether the supplied user is a member of this room.
  def is_member?(participant)
    self.memberships.each do |membership|
      if membership.participant == participant
        return true
      end
    end

    false
  end
end
