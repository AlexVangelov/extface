require_dependency "extface/application_controller"

module Extface
  class DevicesController < ApplicationController
    before_action :set_device, only: [:show, :edit, :update, :destroy]

    # GET /devices
    def index
      @devices = extfaceable.extface_devices.all
    end

    # GET /devices/1
    def show
    end

    # GET /devices/new
    def new
      @device = extfaceable.extface_devices.new
    end

    # GET /devices/1/edit
    def edit
    end

    # POST /devices
    def create
      @device = extfaceable.extface_devices.new(device_params)
      if @device.save
        redirect_to @device, notice: 'Device was successfully created.'
      else
        render action: 'new'
      end
    end

    # PATCH/PUT /devices/1
    def update
      if @device.update(device_params)
        redirect_to @device, notice: 'Device was successfully updated.'
      else
        render action: 'edit'
      end
    end

    # DELETE /devices/1
    def destroy
      @device.destroy
      redirect_to devices_url, notice: 'Device was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_device
        @device = extfaceable.extface_devices.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def device_params
        params.require(:device).permit(:uuid, :name, :driveable_id, :driveable_type)
      end
  end
end
