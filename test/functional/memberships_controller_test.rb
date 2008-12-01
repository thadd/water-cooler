require 'test_helper'

class MembershipsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:memberships)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_membership
    assert_difference('Membership.count') do
      post :create, :membership => { }
    end

    assert_redirected_to membership_path(assigns(:membership))
  end

  def test_should_show_membership
    get :show, :id => memberships(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => memberships(:one).id
    assert_response :success
  end

  def test_should_update_membership
    put :update, :id => memberships(:one).id, :membership => { }
    assert_redirected_to membership_path(assigns(:membership))
  end

  def test_should_destroy_membership
    assert_difference('Membership.count', -1) do
      delete :destroy, :id => memberships(:one).id
    end

    assert_redirected_to memberships_path
  end
end
