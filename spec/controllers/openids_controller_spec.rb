require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenidsController do

  before(:each) do
    @consumer = mock("consumer")
    OpenID::Consumer.stub!(:new).and_return(@consumer)

    AppConfig.stub!(:use_openid).and_return(true)
  end

  it "should not do any processing if OpenID is not enabled" do
    AppConfig.stub!(:use_openid).and_return(false)

    post :create
    response.should redirect_to(:controller => :participants, :action => :new)
    flash[:notice].should == "OpenID login is not enabled"

    post :complete
    response.should redirect_to(:controller => :participants, :action => :new)
    flash[:notice].should == "OpenID login is not enabled"
  end

  describe "GET requests on :create action" do

    it "should fail in create when OpenID isn't in the allowed list" do
      AppConfig.stub!(:openid_allowed_urls).and_return(["http://example.com"])

      post :create, {:openid_url => 'http://example.com'}

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "OpenID URL entered is not in the allowed list"
    end

    it "should fail in create when OpenID is in the ban list" do
      AppConfig.stub!(:openid_banned_urls).and_return(["http://example.com/"])

      post :create, {:openid_url => 'http://example.com/'}

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "OpenID URL is on the banned list"
    end

    it "should fail in create when a non-normalized, banned, OpenID is given" do
      AppConfig.stub!(:openid_banned_urls).and_return(["http://example.com/"])

      post :create, {:openid_url => 'http://example.com'}

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "OpenID URL is on the banned list"
    end

    it "should fail in create when no OpenID is found at the specified URL" do
      @consumer.stub!(:begin).and_raise(OpenID::DiscoveryFailure.new(nil,nil))

      post :create, {:openid_url => 'http://example.com'}

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "Couldn't find an OpenID for that URL"
    end

    it "should redirect from create to the OpenID provider when everything else is ok" do
      @consumer.stub!(:begin).and_raise(OpenID::DiscoveryFailure.new(nil,nil))

      checkid_request = mock(OpenID::Consumer::CheckIDRequest)
      checkid_request.stub!(:add_extension)
      checkid_request.stub!(:return_to_args).and_return(Hash.new)
      checkid_request.stub!(:redirect_url).and_return("http://example.com/")
      @consumer.stub!(:begin).and_return(checkid_request)

      post :create, {:openid_url => 'http://example.com'}

      response.should redirect_to("http://example.com/")
    end
  end

  describe "GET requests on :complete action" do

    before(:each) do
      @oid_response = mock(OpenID::Consumer::Response)
      @oid_response.stub!(:status).and_return(OpenID::Consumer::SUCCESS)
      @oid_response.stub!(:identity_url).and_return("http://example.com/")

      @reg_info = {:timezone => "America/New_York",
        :nickname => "Bob"}
      @oid_response.stub!(:extension_response).and_return(@reg_info)

      @consumer.stub!(:complete).and_return(@oid_response)

      @participant = mock_model(Participant,
                                :username => "http://example.com/")
      @participant.stub!(:name)
      @participant.stub!(:name=)
      @participant.stub!(:active=)
      @participant.stub!(:admin=)
      @participant.stub!(:save)

      Participant.stub!(:new).with(:username => "http://example.com/").and_return(@participant)
    end

    it "should fail if the OpenID login failed" do
      @oid_response.stub!(:status).and_return(OpenID::Consumer::FAILURE)
      @oid_response.stub!(:message).and_return("failed")

      get :complete

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "OpenID login failed (failed)"
    end

    it "should set the time zone if it was supplied" do
      get :complete

      session[:time_zone].should == -18000
    end

    it "should set the time zone to UTC if it wasn't supplied" do
      @oid_response.stub!(:extension_response).and_return(Hash.new)

      get :complete

      session[:time_zone].should == 0
    end

    it "should set the name to the nickname if it is received" do
      @participant.should_receive(:name=).with(@reg_info[:nickname])

      get :complete
    end

    it "should set the name to the identity URL if no nickname is received" do
      @oid_response.stub!(:extension_response).and_return({})
      @participant.should_receive(:name=).with("http://example.com/")

      get :complete
    end

    it "should create a new participant if one wasn't found" do
      Participant.should_receive(:new).with(:username => "http://example.com/").and_return(@participant)
      get :complete
    end

    it "should load an existing participant if one was found" do
      Participant.should_not_receive(:new)
      Participant.should_receive(:find_by_username).with("http://example.com/").and_return(@participant)
      get :complete
    end

    it "should make a participant an admin if they are in the admin list" do
      AppConfig.stub!(:openid_admins).and_return(["http://example.com/"])
      @participant.should_receive(:admin=).with(true)

      get :complete
    end

    it "should not make a participant an admin if they aren't in the admin list" do
      AppConfig.stub!(:openid_admins).and_return(["http://notexample.com/"])
      @participant.should_receive(:admin=).with(false)

      get :complete
    end

    it "should not make a participant an admin if the admin list is empty" do
      AppConfig.stub!(:openid_admins).and_return([])
      @participant.should_receive(:admin=).with(false)

      get :complete
    end

    it "should redirect on a failed save" do
      @participant.should_receive(:save).and_return(false)

      get :complete

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "There was a problem saving to the database"
    end

    describe "on a successful save" do

      it "should set session[:whoami]" do
        @participant.should_receive(:save).and_return(true)

        get :complete

        session[:whoami].should == "http://example.com/"
      end

      it "should create a new keyword if the participant was new" do
        @participant.should_receive(:save).and_return(true)
        @participant.should_receive(:new_record?).and_return(true)
        Keyword.should_receive(:create)

        get :complete
      end

      it "should redirect to the chat room list" do
        @participant.should_receive(:save).and_return(true)

        get :complete

        response.should redirect_to(:controller => :chat_rooms, :action => :index)
        flash[:notice].should == "You have been logged in"
      end
    end
  end
end
