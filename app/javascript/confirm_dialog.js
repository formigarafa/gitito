import { Turbo } from "@hotwired/turbo-rails"

// Asks for the confirmation of a data-turbo-confirm in the dialog of the
// page, #confirm-dialog, instead of the one of the browser. The form can name
// the dialog with data-confirm-title and its button with data-confirm-label.
function confirm(message, form) {
  const dialog = document.getElementById("confirm-dialog")

  if (!dialog?.showModal) return Promise.resolve(window.confirm(message))

  const title = form?.dataset?.confirmTitle
  const messageElement = dialog.querySelector("[data-confirm-message]")

  dialog.querySelector("[data-confirm-title]").textContent = title || message
  messageElement.textContent = message
  messageElement.hidden = !title
  dialog.querySelector("[data-confirm-close=confirm]").textContent = form?.dataset?.confirmLabel || "Confirm"

  return new Promise((resolve) => {
    dialog.returnValue = ""
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
    dialog.showModal()
  })
}

// The buttons close it with their answer; a click outside of it is a "no",
// and so is the Escape key, which closes it with no answer at all.
document.addEventListener("click", ({ target }) => {
  const dialog = document.getElementById("confirm-dialog")
  const button = target.closest?.("[data-confirm-close]")

  if (button) button.closest("dialog").close(button.dataset.confirmClose)
  else if (target === dialog) dialog.close("cancel")
})

if (Turbo.config?.forms) Turbo.config.forms.confirm = confirm
else Turbo.setConfirmMethod(confirm)
