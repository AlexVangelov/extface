require 'test_helper'

module Extface
  class DevicesControllerTest < ActionController::TestCase
    setup do
      @device = extface_devices(:one)
    end

    test "should get index" do
      get :index, shop_id: @device.extfaceable, use_route: :extface
      assert_response :success
      assert_not_nil assigns(:devices)
    end

    test "should get new" do
      get :new, shop_id: @device.extfaceable, use_route: :extface
      assert_response :success
    end

    test "should create device" do
      assert_difference('Device.count') do
        post :create, shop_id: @device.extfaceable, use_route: :extface, device: { driver_class: 'Extface::Driver::GenericPos' }
      end

      assert_redirected_to device_path(assigns(:device))
    end

    test "should show device" do
      get :show, shop_id: @device.extfaceable, use_route: :extface, id: @device
      assert_response :success
    end

    test "should get edit" do
      get :edit, shop_id: @device.extfaceable, use_route: :extface, id: @device
      assert_response :success
    end

    test "should update device" do
      patch :update, shop_id: @device.extfaceable, use_route: :extface, id: @device, device: { name: :new_name }
      assert_redirected_to device_path(assigns(:device))
    end

    test "should destroy device" do
      assert_difference('Device.count', -1) do
        delete :destroy, shop_id: @device.extfaceable, use_route: :extface, id: @device
      end

      assert_redirected_to devices_path
    end
  end
end
