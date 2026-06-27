module AdminHelper
  # Renders an admin breadcrumb trail.
  # crumbs: an array of [label, path] pairs. A pair with a nil path is rendered
  # as the (non-linked) current page. Example:
  #   admin_breadcrumbs([["Dashboard", admin_dashboard_index_path], ["Users", nil]])
  def admin_breadcrumbs(crumbs)
    content_tag(:nav, class: "admin-breadcrumbs") do
      safe_join(
        crumbs.each_with_index.map do |(label, path), i|
          crumb = path ? link_to(label, path) : content_tag(:span, label, class: "current")
          if i < crumbs.size - 1
            safe_join([crumb, content_tag(:span, "›", class: "sep")])
          else
            crumb
          end
        end
      )
    end
  end
end
