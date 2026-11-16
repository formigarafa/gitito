module ApplicationHelper
  # Renders a small form that sends a DELETE request, asking for confirmation
  # first through Turbo's data-turbo-confirm.
  def delete_button(name, path, confirm: t("web-app-theme.confirm", default: "Are you sure?"), **options)
    button_to(
      name,
      path,
      method: :delete,
      class: options.delete(:class) || "link_button",
      form: { class: "button_to inline", data: { turbo_confirm: confirm } },
      **options,
    )
  end
end
