# encoding: utf-8

module ApplicationHelper

  def show_notice
    %w(notice alert).map do | field |
      unless controller.send(field).blank?
        content = ""
        content_tag :div, :class => "flash_block #{field}" do | div |
          content += link_to "закрыть", "#"
          content += content_tag :p, controller.send(field)
          content.html_safe
        end
      end
    end.join.html_safe
  end

end
