module ApplicationHelper
  # What is inside each of the app/assets/icons, read once.
  ICONS = Hash.new do |icons, name|
    icons[name] = Rails.root.join("app/assets/icons/#{name}.svg").read[%r{<svg[^>]*>(.*)</svg>}m, 1].squish.html_safe
  end

  # An icon written into the page, so it takes the colour and the size of the
  # text around it. It says nothing to screen readers: the text beside it does.
  def icon(name, **options)
    tag.svg ICONS[name.to_s], class: [ "icon", options.delete(:class) ], viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round",
      "aria-hidden": true, **options
  end

  # The title of the page, also given to the browser tab. The block is for the
  # actions of the page, and +back+ is a [name, path] to return to.
  def page_header(title, subtitle: nil, back: nil, &block)
    content_for :title, title
    render "shared/page_header", title: title, subtitle: subtitle, back: back, actions: (capture(&block) if block)
  end

  # A link of the main navigation, marked as current in the controllers named by +active+.
  def nav_link(name, path, icon:, active:)
    link_to path, class: "topnav__link", aria: { current: ("page" if active.include?(controller_name)) } do
      icon(icon) + name
    end
  end

  def avatar(user, **options)
    image_tag user.gravatar_url, alt: "", class: [ "avatar", options.delete(:class) ], **options
  end

  # A password field with a button to see what was typed.
  def password_field_with_toggle(form, attribute, **options)
    tag.div class: "input-group", data: { controller: "password-visibility" } do
      form.password_field(attribute, class: "input", data: { password_visibility_target: "input" }, **options) +
        tag.button(icon("eye", class: "icon-off") + icon("eye-off", class: "icon-on"), type: "button",
          class: "input-group__button", aria: { label: "Show password", pressed: false },
          data: { password_visibility_target: "button", action: "password-visibility#toggle" })
    end
  end

  # What the clone URL of a repository of +username+ looks like.
  def clone_url_example(username = "username")
    settings = Rails.configuration.gitito

    "#{settings[:ssh_user]}@#{settings[:ssh_host]}:#{username}/project.git"
  end

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
