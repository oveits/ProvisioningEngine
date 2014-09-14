require 'test_helper'

class ResourcepoolsControllerTest < ActionController::TestCase
  setup do
    @resourcepool = resourcepools(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:resourcepools)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create resourcepool" do
    assert_difference('Resourcepool.count') do
      post :create, resourcepool: { name: @resourcepool.name, resource: @resourcepool.resource }
    end

    assert_redirected_to resourcepool_path(assigns(:resourcepool))
  end

  test "should show resourcepool" do
    get :show, id: @resourcepool
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @resourcepool
    assert_response :success
  end

  test "should update resourcepool" do
    patch :update, id: @resourcepool, resourcepool: { name: @resourcepool.name, resource: @resourcepool.resource }
    assert_redirected_to resourcepool_path(assigns(:resourcepool))
  end

  test "should destroy resourcepool" do
    assert_difference('Resourcepool.count', -1) do
      delete :destroy, id: @resourcepool
    end

    assert_redirected_to resourcepools_path
  end
end
