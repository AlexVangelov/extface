require_dependency "extface/application_controller"

module Extface
  class DevicesController < ApplicationController
    before_action :set_device, only: [:show, :edit, :update, :destroy]

    # GET /devices
    def index
      @devices = extfaceable.extface_devices.load
    end

    # GET /devices/1
    def show
    end

    # GET /devices/new
    def new
      @device = extfaceable.extface_devices.new
      render action: :form
    end

    # GET /devices/1/edit
    def edit
      render action: :form
    end

    # POST /devices
    def create
      @device = extfaceable.extface_devices.new(device_params)
      if @device.save
        redirect_to @device, notice: 'Device was successfully created.'
      else
        render action: :form
      end
    end

    # PATCH/PUT /devices/1
    def update
      if @device.update(device_params)
        redirect_to @device, notice: 'Device was successfully updated.'
      else
        render action: :form
      end
    end

    # DELETE /devices/1
    def destroy
      @device.destroy
      redirect_to devices_url, notice: 'Device was successfully destroyed.'
    end

    def test_page
      set_device
      if @device.fiscal?
        @job = @device.session("Print Test") do |s|
          s.notify "Printing Text"
          s.open_non_fiscal_doc
          s.print "********************************"
          s.print "Extface Print Test".center(32)
          s.print "********************************"
          s.print ""
          s.print "Driver: " + "#{@device.driver.class::NAME}".truncate(24)
          s.close_non_fiscal_doc
          s.notify "Printing finished"
        end
      else
        @job = @device.driver.print_test_page if params[:test_page]
      end
      render action: :show
    end
    
    def fiscal
      set_device
      if @device.fiscal?
        @job = case
          when params[:non_fiscal_test].present? then @device.driver.non_fiscal_test
          when params[:fiscal_test].present? then @device.driver.fiscal_test
          when params[:x_report].present? then @device.driver.x_report_session
          when params[:z_report].present? then @device.driver.z_report_session
          when params[:cancel_fiscal_doc].present? then @device.driver.cancel_doc_session
        end
      end
      render action: :show
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_device
        @device = extfaceable.extface_devices.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def device_params
        params.require(:device).permit(:uuid, :name, :driver_class, :driver_id)
      end
  end
end
