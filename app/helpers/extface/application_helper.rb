module Extface
  module ApplicationHelper

    def bootstrap_class_for flash_type
      case flash_type
        when :success
          "alert-success"
        when :error
          "alert-danger"
        when :alert
          "alert-warning"
        when :notice
          "alert-info"
        else
          flash_type.to_s
      end
    end
    
    def form_group(f, field, control, options = {})
      content_tag(:div, class: 'form-group') do
        f.label(field, class: 'col-sm-2 control-label') +
        content_tag(:div, class: 'col-sm-10 col-md-8') do
          f.send(control, field, options.merge( class: "form-control #{options[:class]}"))
        end
      end
    end
    
    def driver_settings(form, driver)
      content_tag(:div, class: 'panel panel-default') do
        content_tag(:div, class: 'panel-heading') do
          "#{driver.class::NAME} #{t('.settings')}".html_safe
        end +
        content_tag(:div, class: 'panel-body') do
          render "extface/driver/#{driver.class.name.demodulize.underscore}/settings", form: form
        end
      end
    end

    def driver_control(driver)
      content_tag(:div, class: 'panel panel-default') do
        content_tag(:div, class: 'panel-heading') do
          "#{driver.class::NAME} #{t('.control_panel')}".html_safe
        end +
        content_tag(:div, class: 'panel-body') do
          content_tag(:div, class: 'col-sm-8') do
            control_partial = "extface/driver/#{driver.class.name.demodulize.underscore}/control"
            begin
              render control_partial
            rescue ActionView::MissingTemplate
              case
              when driver.fiscal? then 
                render "extface/driver/control_fiscal"
              when driver.print? then 
                render "extface/driver/control_print"
              when driver.report? then 
                render "extface/driver/control_report"
              else
                render "extface/driver/control_raw"
              end
            end
          end +
          content_tag(:div, class: 'col-sm-4') do
            text_area_tag :extface_control_monitor, nil, rows: 8, class: 'form-control'
          end
        end
      end
    end

  end
end
