require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_notification
    assert_difference('Notification.count') do
      post :create, :notification => { }
    end

    assert_redirected_to notification_path(assigns(:notification))
  end

  def test_should_show_notification
    get :show, :id => notifications(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => notifications(:one).id
    assert_response :success
  end

  def test_should_update_notification
    put :update, :id => notifications(:one).id, :notification => { }
    assert_redirected_to notification_path(assigns(:notification))
  end

  def test_should_destroy_notification
    assert_difference('Notification.count', -1) do
      delete :destroy, :id => notifications(:one).id
    end

    assert_redirected_to notifications_path
  end
end
