require 'test_helper'

class ProvisioningsControllerTest < ActionController::TestCase
  setup do
    @provisioning = provisionings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:provisionings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create provisioning" do
    assert_difference('Provisioning.count') do
      post :create, provisioning: { action: @provisioning.action }
    end

    assert_redirected_to provisioning_path(assigns(:provisioning))
  end

  test "should show provisioning" do
    get :show, id: @provisioning
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @provisioning
    assert_response :success
  end

  test "should update provisioning" do
    patch :update, id: @provisioning, provisioning: { action: @provisioning.action }
    assert_redirected_to provisioning_path(assigns(:provisioning))
  end

  test "should destroy provisioning" do
    assert_difference('Provisioning.count', -1) do
      delete :destroy, id: @provisioning
    end

    assert_redirected_to provisionings_path
  end
end
