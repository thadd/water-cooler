require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TranscriptsController do
  before(:each) do
    @me = mock(Participant)
    controller.stub!(:whoami).and_return(@me)
  end

  it "should archive a room" do
    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).twice.and_return(room)
    room.should_receive(:owner).and_return(@me)

    room.should_receive(:archived=).with(true)
    room.should_receive(:save!)

    post :create

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    flash[:notice].should == "Archived the chat room"
  end

  it "should not archive a room if the current user is not the owner or admin" do
    controller.should_receive(:whoami_owns_room?).and_return(false)

    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).and_return(room)

    room.should_not_receive(:archived=)
    room.should_not_receive(:save!)

    post :create

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    flash[:notice].should == "You do not have permissions to archive this room"
  end

  it "should unarchive a room" do
    controller.should_receive(:whoami_owns_room?).and_return(true)

    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).twice.and_return(room)

    room.should_receive(:archived=).with(false)
    room.should_receive(:save!)

    delete :destroy

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    flash[:notice].should == "Unarchived the chat room"
  end

  it "should not unarchive a room if the current user is not owner or admin" do
    controller.should_receive(:whoami_owns_room?).and_return(false)

    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).and_return(room)

    room.should_not_receive(:archived=)
    room.should_not_receive(:save!)

    delete :destroy

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    flash[:notice].should == "You do not have permissions to archive this room"
  end

  it "should show the transcript for a chat room a user is already part of" do
    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).with("1").and_return(room)

    msgs = Array.new
    3.times {|i| msgs << mock("Message-#{i}")}
    room.should_receive(:messages).and_return(msgs)

    part = mock("participants")
    room.should_receive(:participants).and_return(part)

    part.should_receive(:include?).and_return(true)

    get :show, :id => 1

    response.should render_template("transcripts/show")
    assigns[:messages].should == msgs
  end

  it "should show the transcript for an unlocked chat room a user isn't a part of" do
    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).with("1").and_return(room)

    msgs = Array.new
    3.times {|i| msgs << mock("Message-#{i}")}
    room.should_receive(:messages).and_return(msgs)

    part = mock("participants")
    room.should_receive(:participants).and_return(part)

    part.should_receive(:include?).and_return(false)

    room.should_receive(:locked?).and_return(false)

    Membership.should_receive(:create)

    get :show, :id => 1

    response.should render_template("transcripts/show")
    assigns[:messages].should == msgs
  end

  it "should lock out a user if the chat room is archived" do
    room = mock(ChatRoom)
    ChatRoom.should_receive(:find).with("1").and_return(room)

    msgs = Array.new
    3.times {|i| msgs << mock("Message-#{i}")}
    room.should_receive(:messages).and_return(msgs)

    part = mock("participants")
    room.should_receive(:participants).and_return(part)

    part.should_receive(:include?).and_return(false)

    room.should_receive(:locked?).and_return(true)

    Membership.should_not_receive(:create)

    get :show, :id => 1

    response.should redirect_to(:controller => :chat_rooms, :action => :index)
    flash[:notice].should == "Chat room is locked, you can't view transcript"
  end
end
