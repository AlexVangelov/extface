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
