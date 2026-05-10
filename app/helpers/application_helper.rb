module ApplicationHelper
  def status_tag_color(status)
    case status.to_s
    when "pending", "draft"
      "light"
    when "lobby", "races_picking"
      "info"
    when "races_revealed", "map_picking"
      "primary"
    when "in_progress", "ongoing"
      "warning"
    when "completed", "active", "accepting_signups"
      "success"
    else
      "dark"
    end
  end
end
