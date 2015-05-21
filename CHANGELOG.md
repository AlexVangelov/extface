## 0.4.5
  - Datect FP550 layer. Paper cut.
  
## 0.4.2
  - Eltrade fiscal report for period

## 0.4.1
  - Publish win32 client
  - Daisy FP550 driver initial

## 0.4.0
   - Fix Rails 4.1 live stream close without sending any data
   - Single device jobs in queue
   - Limit SSE to 15 sec (TODO reconnect + named events)

## 0.2.6
   - Daisy driver further elaborated
   - Rails 4.1 engine mounted in resources block fix

## 0.2.5
   - Fiscal driver base writing rules
   - Eltrade fp report dates

## 0.2.4
   - Driver Control Panel
   - Print on fiscal device as non fiscal doc

## 0.2.3
   - Driver IO data logger

## 0.2.2
   - Eltrade defer busy response

## 0.2.1
   - Eltrade driver improve
   - Burst transfer (server split requests, client reconnect immediately if not finished)

## 0.2.0
   - Driver clarify responce from device
   - Added experimental Eltrade TM U220 fiscal support

## 0.1.4
  - added route helpers for device pull url and job path: `<model>_extface_device_pull_url`, `<model>_extface_job_path`

## 0.1.3
  - Created demo application at OpenShift
  - Fix invalid multibyte character
  - require `bundle exec rake extface:install:migrations && bundle exec rake db:migrate`

## 0.1.1
  - Remove rdoc, rails 4.0.3 dependancy

## 0.1.0
  - Successfully tested pos printer Star SCP700

## 0.0.8
  - Fix device view
  - HandlerController without Timeout rescue

## 0.0.7
  - config device_timeout
  - rescue error status in handler_controller (tell client not to process data)

## 0.0.6
 - Views decorations
 - Fix ActiveRecord connection close at job end in background

## 0.0.5

 - Added changelog
 - Use namespaced redis
 - Fix handler controller redis instance
