require 'test_helper'

class KeywordsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:keywords)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_keyword
    assert_difference('Keyword.count') do
      post :create, :keyword => { }
    end

    assert_redirected_to keyword_path(assigns(:keyword))
  end

  def test_should_show_keyword
    get :show, :id => keywords(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => keywords(:one).id
    assert_response :success
  end

  def test_should_update_keyword
    put :update, :id => keywords(:one).id, :keyword => { }
    assert_redirected_to keyword_path(assigns(:keyword))
  end

  def test_should_destroy_keyword
    assert_difference('Keyword.count', -1) do
      delete :destroy, :id => keywords(:one).id
    end

    assert_redirected_to keywords_path
  end
end
