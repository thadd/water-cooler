require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ParticipantsController do
  describe "tests for ApplicationController" do
    it "should send the user to the login page if they're not logged in" do
      controller.should_receive(:whoami).and_return(nil)

      get :edit, :id => 1

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "Please log in"
    end

    it "should send the user to the login page if they're not logged in" do
      Participant.should_receive(:find_by_username)

      get :edit, :id => 1

      response.should redirect_to(:controller => :participants, :action => :new)
      flash[:notice].should == "Please log in"
    end
  end

  describe "GET requests on :new action" do
    it "should log a user out if they are currently logged in" do
      session[:whoami] = "dummy"
      get :new

      flash[:notice].should == "You have been logged out"
      session[:whoami].should be_nil
    end
  end

  describe "POST requests on :create action" do
    it "should not do anything if dummy login is disabled" do
      AppConfig.stub!(:use_dummy_login).and_return(false)

      post :create

      response.should redirect_to(:action => :new)
      flash[:notice].should == "Login method unallowed"
    end

    it "should log the user in (test for getting full coverage, don't need to test this section)" do
      AppConfig.stub!(:use_dummy_login).and_return(true)

      post :create, :participant => {:username => "dummy"} 

      response.should redirect_to(:controller => :chat_rooms, :action => :index)
      flash[:notice].should == "You have been logged in"
    end

    it "should redirect if login fails (test for getting full coverage, don't need to test this section)" do
      AppConfig.stub!(:use_dummy_login).and_return(true)
      part = mock(Participant)
      Participant.stub!(:new).and_return(part)
      part.stub!(:new_record?).and_return(true)
      part.stub!(:name=)
      part.stub!(:active=)
      part.stub!(:admin=)
      part.should_receive(:save).and_return(false)

      post :create, :participant => {:username => "dummy"} 

      response.should redirect_to(:action => :new)
      flash[:notice].should == "There was a problem saving to the database"
    end
  end

  describe "GET requests on :edit action" do
    before(:each) do
      @part = mock(Participant)
      @part.should_receive(:id).and_return(1)
      controller.stub!(:whoami).and_return(@part)
    end

    it "should fail if the current user is not the one being modified" do
      get :edit, :id => 2

      response.should redirect_to(:controller => :chat_rooms, :action => :index)
      flash[:notice].should == "Access forbidden"
    end

    it "should load the user and render" do
      Participant.should_receive(:find).and_return(@part)

      get :edit, :id => 1

      response.should be_success
      assigns[:participant].should == @part
      response.should render_template(:edit)
    end
  end

  describe "PUT requests on :update action" do
    before(:each) do
      @part = mock(Participant)
      @part.should_receive(:id).and_return(1)

      controller.stub!(:whoami).and_return(@part)
      Participant.stub!(:find).and_return(@part)
    end

    it "should fail if the logged in user is not the one being modified" do
      put :update, :id => 2

      response.should redirect_to(:controller => :chat_rooms, :action => :index)
      flash[:notice].should == "Access forbidden"
    end

    it "should fail gracefully if the update doesn't work" do
      @part.should_receive(:update_attributes).and_return(false)
      @part.should_receive(:name)

      put :update, :id => 1

      response.should render_template('participants/edit')
      flash[:notice].should == "Failed to save changes"
    end

    describe "nickname change" do
      before(:each) do
        @part.should_receive(:update_attributes).and_return(true)

        @key = mock(Keyword)
      end

      it "should reset the keyword if the name changed and the old name was a keyword" do
        @part.should_receive(:name).exactly(3).times.and_return("old name", "new name", "new name")

        Keyword.should_receive(:find).and_return(@key)
        @key.should_receive(:text=).with("new name")
        @key.should_receive(:save!)

        put :update,
          :id => 1,
          :form_type => "nickname",
          :participant => {:name => "new name"}

        flash[:notice].should == "Nickname changed"
        response.should redirect_to(:controller => :chat_rooms, :action => :index)
      end

      it "should not reset the keyword if the name changed and the old name wasn't a keyword" do
        @part.should_receive(:name).exactly(2).times.and_return("old name", "new name")

        Keyword.should_receive(:find).and_return(nil)
        @key.should_not_receive(:text=)
        @key.should_not_receive(:save!)

        put :update,
          :id => 1,
          :form_type => "nickname",
          :participant => {:name => "new name"}

        flash[:notice].should == "Nickname changed"
        response.should redirect_to(:controller => :chat_rooms, :action => :index)
      end
    end

    describe "status change" do
      before(:each) do
        @part.should_receive(:update_attributes).and_return(true)
        @part.should_receive(:name).once
      end

      it "should clear the away message and mark the person active if available is checked" do
        @part.should_receive(:active=).with('')
        @part.should_receive(:save!)

        put :update,
          :id => 1,
          :form_type => "status",
          :participant => {:name => "new name"},
          :available => true

        flash[:notice].should be_nil
        response.should redirect_to(:controller => :chat_rooms, :action => :index)
      end

      it "should set all memberships to inactive when available is not checked" do
        memberships = Array.new

        3.times do |i|
          membership = mock("Membership #{i}")
          membership.should_receive(:active=).with(false)
          membership.should_receive(:save)
          memberships << membership
        end

        @part.should_receive(:memberships).and_return(memberships)

        put :update,
          :id => 1,
          :form_type => "status",
          :participant => {:name => "new name"}

        flash[:notice].should be_nil
        response.should redirect_to(:controller => :chat_rooms, :action => :index)
      end
    end
  end
end
