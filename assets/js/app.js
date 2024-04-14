// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import FlashyHooks from "flashy";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

let Hooks = {...FlashyHooks};

let actionsOpened = {};

const mountMenu = (name, button, menu) => {
  button.addEventListener("click", () => {
    if (actionsOpened[name] === undefined) actionsOpened[name] = false;

    if (actionsOpened[name]) {
      actionsOpened[name] = false;
      menu.classList.remove(
        "ease-out",
        "duration-100",
        "opacity-100",
        "scale-100"
      );
      menu.classList.add("duration-75", "opacity-0", "scale-95");
    } else {
      actionsOpened[name] = true;
      menu.classList.remove("ease-in", "duration-75", "opacity-0", "scale-95");
      menu.classList.add("duration-100", "opacity-100", "scale-100");
    }
  });
};

Hooks.ActionMenu = {
  mounted() {
    mountMenu(
      "actions",
      document.getElementById("menu-button"),
      document.getElementById("actions-menu")
    );
  },
};

Hooks.SplitMenu = {
  mounted() {
    mountMenu(
      this.el.id,
      this.el.querySelector(".split-button-dropdown"),
      this.el.querySelector(".split-button-items")
    );
  },
};

Hooks.EventTime = {
  mounted() {
    const stored = document.getElementById("event-time");
    const d = new Date(stored.value)
    const dateTimeLocalValue = (new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString()).slice(0, -1);
    this.el.value = dateTimeLocalValue;
    this.el.onchange = () => {
      stored.value = (new Date(this.el.value)).toISOString();
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

let menuOpen = false;

// document.getElementById("open-sidebar").addEventListener("click", () => {
//   menuOpen = true;
// });

let listeners = (a) =>
  a.addEventListener("click", () => {
    if (!menuOpen) {
      menuOpen = true;
      document.getElementById("off-canvas-menu").classList.add("translate-x-0");

      document
        .getElementById("off-canvas-menu")
        .classList.remove("-translate-x-full");

      document.getElementById("close-sidebar").classList.add("opacity-100");

      document.getElementById("close-sidebar").classList.remove("opacity-0");

      document.getElementById("menu-backdrop").classList.add("opacity-100");

      document.getElementById("menu-backdrop").classList.remove("opacity-0");

      document.getElementById("off-canvas").classList.add("z-50");

      document.getElementById("off-canvas").style.display = "initial";
    } else {
      menuOpen = false;
      document
        .getElementById("off-canvas-menu")
        .classList.add("-translate-x-full");

      document
        .getElementById("off-canvas-menu")
        .classList.remove("translate-x-0");

      document.getElementById("close-sidebar").classList.add("opacity-0");

      document.getElementById("close-sidebar").classList.remove("opacity-100");

      document.getElementById("menu-backdrop").classList.add("opacity-0");

      document.getElementById("menu-backdrop").classList.remove("opacity-100");
      document.getElementById("off-canvas").classList.remove("z-50");
      document.getElementById("off-canvas").style.display = "none";
    }
  });

listeners(document.getElementById("open-sidebar"));
listeners(document.getElementById("close-sidebar"));
