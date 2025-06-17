import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    open(event) {
        const dialog = document.getElementById(event.params.dialog);
        if (dialog) {
            dialog.showModal();
        }
    }

    close(event) {
        const dialog = document.getElementById(event.params.dialog);
        if (dialog) {
            dialog.close();
        }
    }
}
