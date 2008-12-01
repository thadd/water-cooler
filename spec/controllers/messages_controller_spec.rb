require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MessagesController do
  before(:each) do
    @me = mock("Participant-me")
    @me.stub!(:memberships).and_return([@mem])
    @me.stub!(:away?).and_return(false)
    @me.stub!(:pending_notification?).and_return(false)
    controller.stub!(:whoami).and_return(@me)

    @msgs = Array.new
    10.times do |i|
      msg = mock("Message-#{i}")
      msg.stub!(:id).and_return(i)
      @msgs << msg
    end

    @message_scope = mock("Message scope")
    @message_scope.stub!(:find).and_return(@msgs)

    @room = mock(ChatRoom)
    @room.stub!(:participants).and_return([@me])
    @room.stub!(:name).and_return("Dummy")
    @room.stub!(:archived?).and_return(false)
    @room.stub!(:messages).and_return(@message_scope)

    ChatRoom.stub!(:find).and_return(@room)

    @mem = mock(Membership)
    Membership.stub!(:joining).and_return(@mem)
  end

  it "should fail if the user isn't in the room" do
    @room.should_receive(:participants).and_return([])

    xhr :get, :index, :chat_room_id => 1

    flash[:notice].should == "You are not a member of this chat room"
    response.should be_redirect
  end

  describe "GET requests on :index action" do
    it "should evict a user who doesn't have a valid membership" do
      Membership.should_receive(:joining).and_return(nil)

      xhr :get, :index, :chat_room_id => 1

      flash[:notice].should == "You have been evicted from Dummy by the owner or an admin."
      assigns[:member_should_be_evicted].should == true
    end

    it "should evict a user if the room has been archived" do
      @room.should_receive(:archived?).and_return(true)

      xhr :get, :index, :chat_room_id => 1

      flash[:notice].should == "Chat room is archived"
      assigns[:member_should_be_evicted].should == true
    end

    it "should set the current highest message when the message list is empty" do
      max_msg = mock("Maximum message")
      @message_scope.should_receive(:find).and_return([])
      @message_scope.should_receive(:maximum).with(:id).and_return(max_msg)

      xhr :get, :index, :chat_room_id => 1

      assigns[:current_highest_message].should == max_msg
    end

    it "should set the current highest message when the message list is empty" do
      @message_scope.should_receive(:find).and_return(@msgs)

      xhr :get, :index, :chat_room_id => 1

      assigns[:current_highest_message].should == 9
    end

    it "should clear the notification list when the user is not away" do
      notes = Array.new
      notes_to_destroy = Array.new
      msgs = Array.new

      2.times do |i|
        n = mock("Notification-#{i}")
        m = mock("Message-#{i}")

        m.should_receive(:chat_room).and_return(nil)
        n.should_receive(:message).twice.and_return(m)

        notes << n
        msgs << m
      end

      2.times do |i|
        n = mock("Notification-#{i+2}")
        m = mock("Message-#{i+2}")

        m.should_receive(:chat_room).and_return(@room)
        n.should_receive(:message).twice.and_return(m)

        notes << n
        msgs << m
        notes_to_destroy << n
      end

      Notification.should_receive(:find).and_return(notes)
      Notification.should_receive(:destroy).with(notes_to_destroy)

      xhr :get, :index, :chat_room_id => 1

      assigns[:messages_with_notifications].should == msgs
    end

    it "should set pending notification attributes when appropriate" do
      @me.should_receive(:pending_notification?).and_return(true)
      @me.should_receive(:pending_notification=).with(false)
      @me.should_receive(:save!)

      xhr :get, :index, :chat_room_id => 1

      assigns[:should_play_notification_sound].should == true
    end

    it "should render the index template" do
      xhr :get, :index, :chat_room_id => 1

      response.should be_success
      response.should render_template('messages/index')
    end
  end

  describe "POST requests on :create action" do
    it "should create a new message if it's not empty" do
      message = mock(Message)

      Message.should_receive(:new).and_return(message)
      message.should_receive(:content).twice.and_return("This is a message")
      message.should_receive(:participant=).with(@me)
      message.should_receive(:chat_room=).with(@room)

      message.should_receive(:save)

      xhr :post, :create, :chat_room_id => 1

      response.should be_success
      response.should render_template('messages/create')
    end
  end
end
