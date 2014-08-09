require 'test_helper'
require 'generators/extface/driver/driver_generator'

module Extface
  class DriverGeneratorTest < Rails::Generators::TestCase
    tests Extface::DriverGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
