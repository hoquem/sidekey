// Turns the keycap deck into the page's navigation: the chosen key shows a faint amber edge for a
// moment (the app's "pending" state), then lights, and its panel shows below. Without JavaScript
// every panel is visible and keys are plain anchors.
(function () {
  const keys = Array.from(document.querySelectorAll(".key[data-panel]"));
  const panels = Array.from(document.querySelectorAll(".panel"));
  const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const pendingMs = 140;

  function show(id, focus) {
    const panel = document.getElementById(id) || document.getElementById("download");
    panels.forEach((p) => p.classList.toggle("shown", p === panel));
    keys.forEach((k) => {
      k.classList.remove("pending");
      k.setAttribute("aria-current", k.dataset.panel === panel.id ? "true" : "false");
      // The download key stays lit at rest so the primary action is always obvious.
      k.classList.toggle("lit", k.dataset.panel === "download" && panel.id === "download");
    });
    if (focus) {
      panel.setAttribute("tabindex", "-1");
      panel.focus({ preventScroll: true });
      panel.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" });
    }
  }

  keys.forEach((key) => key.addEventListener("click", (event) => {
    event.preventDefault();
    history.replaceState(null, "", `#${key.dataset.panel}`);
    if (reduceMotion) return show(key.dataset.panel, true);
    keys.forEach((k) => k.classList.remove("lit"));
    key.classList.add("pending");
    setTimeout(() => show(key.dataset.panel, true), pendingMs);
  }));

  // Links and the back button change only the hash; follow them like a key press.
  window.addEventListener("hashchange", () => show(location.hash.slice(1) || "download", true));

  show(location.hash.slice(1) || "download", false);
})();
