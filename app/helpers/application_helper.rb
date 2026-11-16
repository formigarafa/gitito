# frozen_string_literal: true

module ApplicationHelper
  # Renders a small form that sends a DELETE request, asking the browser for
  # confirmation first. Works without any JavaScript framework (the old
  # `link_to ..., method: :delete, confirm: ...` relied on rails.js UJS).
  def delete_button(name, path, confirm: t("web-app-theme.confirm", default: "Are you sure?"), **options)
    button_to(
      name,
      path,
      method: :delete,
      class: options.delete(:class) || "link_button",
      form: {class: "button_to inline", onsubmit: "return confirm(#{confirm.to_json})"},
      **options,
    )
  end
end
