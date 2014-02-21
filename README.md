Extface<sup>&hearts;</sup>
========

External Interfaces for Cloud-Based Applications (Rails 4)

Using Cash Registers, Fiscal and POS printers without physical connection between the device, application server and the end user. 
Can also be used for remotely reading CDR logs from PBX systems and actually supports data exchange with all low-speed devices having serial, parallel or USB* interface.

## It's just the beggining

    gem 'extface'
    
    bundle install
    
    bundle exec rake extface:install:migrations
    
To add external interfaces to `Shop` model, use mapper `extface_for` in `config/routes.rb`, example:

    resources :shops do 
      extface_for :shop
    end
  
Add `has_extface_devices` in your `/app/models/shop.rb`

Extface engine will be visible at `link_to 'Extface', shop_extface_path(@shop)`

Create a device with driver `Generic Pos Print`.
Copy the `Pull URL`, visible on device's show page.

To simulate client side of the system you can use bash script (replace the URL with your one):

    while true; do RESULT=$(curl -u extface:extface -c extface -b extface -s http://localhost:3000/shops/1/shop_extface/bb6ac841cf239ab89b967352c40e4b39); if [ -z "$RESULT" ]; then sleep 5; else echo -e "$RESULT"; sleep 1; fi done
  
Hit The `Print Test Page` and you will see result in you console.

Output can be forwarded to real device by adding ` > /dev/ttyS0` at the end example script.

## Usage

    job = extface_device.session do |s|
      s.print "some data\r\n"
      10.times do |i|
        s.print "Line #{i}\r\n"
      end
    end

The result of this block returns immediately, and the job is executed in background.
Job execution can be monitored with EventStream (SSE) at `extface.job_url(job)`

Extface is happy with Unicorn workers, even recommended it!

The project is still in workflow development stage.
It is focused on the following tasks:

  Easy and clear integration.
  Reliability.
  Low consumption of server and client resources.
  Maintenance of a large number of protocols and devices.
