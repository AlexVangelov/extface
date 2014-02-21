require 'test_helper'

module Extface
  class JobsControllerTest < ActionController::TestCase
    setup do
      @job = extface_jobs(:one)
    end

    test "should show job" do
      get :show, use_route: :extface, id: @job
      assert_response :success
    end
  end
end
