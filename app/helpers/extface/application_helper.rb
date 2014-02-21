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

  end
end
