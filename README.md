Extface<sup>&hearts;</sup>
========

External Interfaces for Cloud-Based Applications (Rails 4)

Using Cash Registers, Fiscal and POS printers without physical connection between the device, application server and the end user. 
Can also be used for remotely reading CDR logs from PBX systems and actually supports data exchange with all low-speed devices having serial, parallel or USB* interface.
Extface allows multiple jobs to be executed in queue, and provides job progress monitor through Server-Sent Events.

## It's just the beginning

    gem 'extface'
    
    bundle install
    
    bundle exec rake extface:install:migrations
    
    bundle exec rake db:migrate
    
Communication with devices is realized through Redis server, so it is required. Read more down.

Home page: [http://extface.com](http://extface.com)

Demo application: [http://example-extface.rhcloud.com](http://example-extface.rhcloud.com)

Demo application source code: [https://github.com/AlexVangelov/extface-example](https://github.com/AlexVangelov/extface-example)
    
To add external interfaces to `Shop` model, use mapper `extface_for` in `config/routes.rb`, example:

    resources :shops do 
      extface_for :shop
    end
  
Add `has_extface_devices` in your `/app/models/shop.rb`

Extface engine will be visible at `link_to 'Extface', shop_extface_path(@shop)`

Create a device with driver `Generic Pos Print`.
Copy the `Pull URL`, visible on device's show page.

To simulate client side (one way communication) of the system you can use bash script (replace the URL with your one):

    while true; do RESULT=$(curl -u extface:extface -c extface -b extface -s http://localhost:3000/shops/1/shop_extface/bb6ac841cf239ab89b967352c40e4b39); if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi done

Hit The `Print Test Page` and you will see result in you console.

Output can be forwarded to real device by adding ` > /dev/ttyS0` at the end example script.

## Extface Client

(Update 2014-08-13)
To allow testing the module without having a hardware client, I just realize win32 version, available for download in `bin/extface_client_win32` [extface.exe](https://github.com/AlexVangelov/extface/blob/master/bin/extface_client_win32/extface.exe)
It's fully featured client for tests and development. The only limit is that it does not support SSL and is not recommended to use in production.
Command line options:

    extface.exe PullUrl [PORT][,BoudRate][,ByteSyzeParityStopBits][,Control]
    Options: Parity: E|M|N|O|S; StopBits: 1|1.5|2; Control: N|H|X (None|Hardware|XON/XOF)
    Default: COM1,9600,8N1,N

## Usage

    job = extface_device.session do |s|
      s.print "some data\r\n"
      10.times do |i|
        s.print "Line #{i}\r\n"
      end
    end

The result of this block returns immediately, and the job is executed in background.
Job execution can be monitored with EventStream (SSE) at `shop_extface_job_path(shop, job)`

Extface is happy with Unicorn workers, even recommended it!

The project is still in workflow development stage.
It is focused on the following tasks:

  Easy and clear integration.
  Reliability.
  Low consumption of server and client resources.
  Maintenance of a large number of protocols and devices.


## Rails engines

Extface is intended to work properly with multiple instances in rails engines. Possible routing mappers:

    resources :shops do
      extface_for :shop, interfaceable_type: 'Market::Shop', controller_include: 'Market::ShopController'
    end
    
Where `Market::ShopController` is Module that includes application before actions, like authentication, set locale and what ever.

    scope ':shop_uuid' do
      extface_for :shop, interfaceable_type: 'Market::Shop', interfaceable_param: :shop_uuid, controller_include: 'Market::ShopController'
    end
    
This will mount extface at `market/:shop_uuid/shop_extface` and will try to find shop instance by `Market::Shop.find_by(uuid: params[:shop_uuid])`

## Redis connection string

Create `config/initializers/extface.rb`:

    Extface.setup do |config|
      #config.redis_connection_string = "redis://username:password@my.host:6389"
      #config.device_timeout = 10 #seconds to wait before cancel the job if there is no activity on the device
    end


## Views & Layout

Views as designed for twitter bootstrap CSS. Engine layout can be replaced by creating `app/views/layouts/extface/application.html.erb` in your engine/main_app.
