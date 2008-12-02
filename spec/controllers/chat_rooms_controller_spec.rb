require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChatRoomsController do
  before(:each) do
    @me = mock("Participant-me")
    controller.stub!(:whoami).and_return(@me)
  end

  describe "GET requests on :index action" do
    it "should set all the list variables" do
      @me.stub!(:memberships).and_return(Array.new)

      active = mock("Active rooms")
      inactive = mock("Inactive rooms")

      ChatRoom.should_receive(:find).twice.and_return(active, inactive)

      notes = Array.new
      3.times do |i|
        notes << mock("Notification-#{i}")
      end

      Notification.should_receive(:find).and_return(notes)

      get :index

      assigns[:active_chat_rooms].should == active
      assigns[:inactive_chat_rooms].should == inactive
      assigns[:notifications].should == notes
    end

    it "should deactivate each membership" do
      m = Array.new
      3.times do |i|
        temp = mock("Membership-#{i}")
        temp.should_receive(:active?).and_return(true)
        temp.should_receive(:active=).with(false)
        temp.should_receive(:save!)
        m << temp
      end

      @me.should_receive(:memberships).and_return(m)

      get :index
    end
  end

  describe "GET requests on show action" do
    before(:each) do
      @mem = mock(Membership)
      @mem.stub!(:active=)
      @mem.stub!(:save!)

      Membership.stub!(:joining).and_return([@mem])

      @msg_scope = mock("Messages for named scope")
      @msg_scope.stub!(:since).and_return([])
      @msg_scope.stub!(:limit).and_return([])

      @me.stub!(:away?)
      @me.stub!(:keywords).and_return([])
      @me.stub!(:rooms_around).and_return([])

      @room = mock(ChatRoom)
      @room.stub!(:id).and_return(1)
      @room.stub!(:memberships).and_return([@mem])
      @room.stub!(:messages).and_return(@msg_scope)
      @room.stub!(:archived?).and_return(false)
      @room.stub!(:participants).and_return([@me])
      @room.stub!(:locked?).and_return(false)

      ChatRoom.stub!(:find_by_id).and_return(@room)
    end

    it "should fail if the chat room doesn't exist" do
      ChatRoom.should_receive(:find_by_id).with("1").and_return(nil)

      get :show, :id => 1

      flash[:notice].should == "Chat room doesn't exist. Maybe the owner deleted it?"
      response.should redirect_to(:action => :index)
    end

    it "should fail if the chat room is archived" do
      ChatRoom.should_receive(:find_by_id).with("1").and_return(@room)
      @room.should_receive(:archived?).and_return(true)

      # Make sure its asking for URL for transcript URL
      controller.should_receive(:url_for).with({:action => "show",
                                               :only_path => false,
                                               :controller => "transcripts",
                                               :use_route => :transcript,
                                               :id => @room}).and_return("http://test.host/dummy")

      get :show, :id => 1

      flash[:notice].should == "Chat room is archived, loading transcript"
      response.should redirect_to("dummy")
    end

    it "should create a new membership if the user isn't in the room" do
      @room.should_receive(:participants).and_return([])
      @room.should_receive(:locked?).and_return(false)

      Membership.should_receive(:create).with(:participant => @me,
                                              :chat_room => @room)

      get :show, :id => 1
    end

    it "should fail if a new user attempts to enter a locked room" do
      @room.should_receive(:participants).and_return([])
      @room.should_receive(:locked?).and_return(true)

      Membership.should_not_receive(:create)

      get :show, :id => 1

      flash[:notice].should == "Chat room is locked, you can't join"
      response.should redirect_to(:action => :index)
    end

    it "should mark the current membership as active when the user isn't away" do
      @mem.should_receive(:active=).with(true)
      @mem.should_receive(:save!)

      get :show, :id => 1
    end

    it "should mark the current membership as inactive when the user is away" do
      @me.stub!(:away?).and_return(true)
      @mem.should_receive(:active=).with(false)
      @mem.should_receive(:save!)

      get :show, :id => 1
    end

    it "should set the memberships for the member list" do
      @room.should_receive(:memberships).and_return([@mem])

      get :show, :id => 1

      assigns[:memberships].should == [@mem]
    end

    it "should get recent messages if there are any" do
      msgs = Array.new
      10.times do |i|
        msgs << mock("Message-#{i}")
      end
      @msg_scope.should_receive(:since).and_return(msgs)

      get :show, :id => 1

      assigns[:messages].should == msgs
    end

    it "should get 50 messages if there are no recent ones" do
      msgs = Array.new
      50.times do |i|
        msgs << mock("Message-#{i}")
      end
      @msg_scope.should_receive(:since).and_return([])
      @msg_scope.should_receive(:limit).with(50).and_return(msgs.reverse)

      get :show, :id => 1

      assigns[:messages].should == msgs
    end

    it "should set the @current_highest_message to -1 if there are no messages" do
      @msg_scope.should_receive(:since).and_return([])
      @msg_scope.should_receive(:limit).with(50).and_return([])

      get :show, :id => 1

      assigns[:current_highest_message].should == -1
    end

    it "should set the @current_highest_message to id of the last message" do
      msgs = Array.new
      10.times do |i|
        m = mock("Message-#{i}")
        m.stub!(:id).and_return(i)
        msgs << m
      end
      @msg_scope.should_receive(:since).and_return(msgs)

      get :show, :id => 1

      assigns[:current_highest_message].should == 9
    end

    it "should set the notifications list" do
      notes = Array.new
      10.times do |i|
        n = mock("Notification-#{i}")
        m = mock("Message-#{i}")
        m.stub!(:chat_room).and_return(mock(ChatRoom))
        n.stub!(:message).and_return(m)
        notes << n
      end

      Notification.should_receive(:for).with(@me).and_return(notes)

      get :show, :id => 1

      assigns[:notifications].should == notes
    end

    it "should set the keyword list" do
      keys = Array.new
      10.times do |i|
        keys << mock("Keyword-#{i}")
      end

      @me.should_receive(:keywords).and_return(keys)

      get :show, :id => 1

      assigns[:keywords].should == keys
    end

    it "should set @my_memberships from the current user's list" do
      mems = Array.new
      5.times do |i|
        mems << mock("Membership-#{i}")
      end

      @me.should_receive(:rooms_around).and_return(mems)

      get :show, :id => 1

      assigns[:my_memberships].should == mems
    end

    it "should get a list of messages and chat rooms that have notifications" do
      notes = Array.new
      msgs = Array.new
      rooms = Array.new
      10.times do |i|
        n = mock("Notification-#{i}")
        m = mock("Message-#{i}")
        c = mock("ChatRoom-#{i}")

        n.should_receive(:message).twice().and_return(m)
        m.should_receive(:chat_room).and_return(c)

        notes << n
        msgs << m
        rooms << c
      end

      Notification.should_receive(:for).with(@me).and_return(notes)

      get :show, :id => 1

      assigns[:messages_with_notifications].should == msgs
      assigns[:chat_rooms_with_notifications].should == rooms
    end

    it "should render the show template if everything is successful" do
      get :show, :id => 1

      response.should be_success
      response.should render_template('chat_rooms/show')
    end
  end

  describe "GET requests on :new action" do
    it "should set a dummy chat room and render the form" do
      c = mock(ChatRoom)
      ChatRoom.should_receive(:new).and_return(c)

      get :new

      assigns[:chat_room].should == c
      response.should render_template('chat_rooms/new')
    end
  end

  describe "POST requests on :create action" do
    before(:each) do
      owned_rooms = mock("Owned rooms")

      @room = mock(ChatRoom)
      owned_rooms.should_receive(:build).with("name" => "New room").and_return(@room)

      @me.should_receive(:owned_rooms).and_return(owned_rooms)
    end

    it "should create a new chat room owned by the current user" do
      @room.should_receive(:save).and_return(true)
      controller.should_receive(:url_for).with(@room).and_return("http://test.host/dummy")

      post :create, :chat_room => {:name => "New room"}

      flash[:notice].should == "Chat room created"
      response.should redirect_to("dummy")
    end

    it "should re-render the new template on save failure" do
      @room.should_receive(:save).and_return(false)

      post :create, :chat_room => {:name => "New room"}

      response.should render_template('chat_rooms/new')
    end
  end

  describe "POST requests on :create action" do
    before(:each) do
      owned_rooms = mock("Owned rooms")

      @room = mock(ChatRoom)
      owned_rooms.should_receive(:build).with("name" => "New room").and_return(@room)

      @me.should_receive(:owned_rooms).and_return(owned_rooms)
    end

    it "should create a new chat room owned by the current user" do
      @room.should_receive(:save).and_return(true)
      controller.should_receive(:url_for).with(@room).and_return("dummy")

      post :create, :chat_room => {:name => "New room"}

      flash[:notice].should == "Chat room created"
      response.should be_redirect
    end

    it "should re-render the new template on save failure" do
      @room.should_receive(:save).and_return(false)

      post :create, :chat_room => {:name => "New room"}

      response.should render_template('chat_rooms/new')
    end
  end

  describe "PUT requests on :update action" do
    before(:each) do
      request.env["HTTP_REFERER"] = "/dummy"
    end

    it "should fail if the current user doesn't own the room" do
      controller.should_receive(:whoami_owns_room?).and_return(false)
      ChatRoom.should_receive(:find).and_return(mock(ChatRoom))

      put :update, :id => 1

      flash[:notice].should == "You do not have permissions to modify this room"
      response.should redirect_to(:action => :index)
    end

    it "should lock a room" do
      controller.should_receive(:check_for_room_owner).and_return(true)
      @room = mock(ChatRoom)
      ChatRoom.should_receive(:find).and_return(@room)

      @room.should_receive(:update_attributes).with('locked' => true)
      @room.should_receive(:locked?).and_return(true)

      put :update, :chat_room => {:locked => true}

      flash[:notice].should == 'Chat room now locked. No one else can join.'
      response.should redirect_to('dummy')
    end

    it "should unlock a room" do
      controller.should_receive(:check_for_room_owner).and_return(true)
      @room = mock(ChatRoom)
      ChatRoom.should_receive(:find).and_return(@room)

      @room.should_receive(:update_attributes).with('locked' => false)
      @room.should_receive(:locked?).and_return(false)

      put :update, :chat_room => {:locked => false}

      flash[:notice].should == 'Chat room now unlocked. Anyone can join.'
      response.should redirect_to('dummy')
    end
  end

  describe "DELETE requests on :destroy action" do
    it "should fail if the current user doesn't own the room" do
      controller.should_receive(:whoami_owns_room?).and_return(false)
      ChatRoom.should_receive(:find).with('1').and_return(mock(ChatRoom))

      delete :destroy, :id => 1

      flash[:notice].should == "You do not have permissions to modify this room"
      response.should redirect_to(:action => :index)
    end

    it "should delete a room" do
      controller.should_receive(:check_for_room_owner).and_return(true)
      @room = mock(ChatRoom)
      ChatRoom.should_receive(:find).with('1').and_return(@room)

      @room.should_receive(:name).and_return("dummy")
      @room.should_receive(:destroy)

      delete :destroy, :id => 1

      flash[:notice].should == 'Deleted chat room "dummy"'
      response.should redirect_to(:action => :index)
    end
  end
end
