/* Sweet Magic Popcorn — site behaviour
   Progressive enhancement only: everything works without JS. */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------------------------------------------- mobile drawer --- */
  var toggle = document.querySelector(".nav-toggle");
  var drawer = document.getElementById("mobile-nav");

  function closeDrawer() {
    if (!toggle || !drawer) return;
    toggle.setAttribute("aria-expanded", "false");
    drawer.classList.remove("is-open");
    document.body.style.overflow = "";
  }

  if (toggle && drawer) {
    toggle.addEventListener("click", function () {
      var open = toggle.getAttribute("aria-expanded") === "true";
      toggle.setAttribute("aria-expanded", String(!open));
      drawer.classList.toggle("is-open", !open);
      document.body.style.overflow = open ? "" : "hidden";
    });

    drawer.addEventListener("click", function (e) {
      if (e.target.closest("a")) closeDrawer();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeDrawer();
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 960) closeDrawer();
    });
  }

  /* --------------------------------------------------- sticky header ---- */
  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () {
      header.classList.toggle("is-stuck", window.scrollY > 8);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  /* ------------------------------------------------- reveal on scroll --- */
  var reveals = document.querySelectorAll(".reveal");
  if (reveals.length) {
    if (reduceMotion || !("IntersectionObserver" in window)) {
      reveals.forEach(function (el) { el.classList.add("is-in"); });
    } else {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-in");
            io.unobserve(entry.target);
          }
        });
      }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
      reveals.forEach(function (el) { io.observe(el); });
    }
  }

  /* ---------------------------------------------------------- tabs ------ */
  document.querySelectorAll("[data-tabs]").forEach(function (group) {
    var buttons = group.querySelectorAll(".tab-btn");
    var panels = group.querySelectorAll(".tab-panel");

    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        var target = btn.getAttribute("aria-controls");
        buttons.forEach(function (b) {
          b.setAttribute("aria-selected", String(b === btn));
          b.setAttribute("tabindex", b === btn ? "0" : "-1");
        });
        panels.forEach(function (p) {
          p.hidden = p.id !== target;
        });
        if (history.replaceState) history.replaceState(null, "", "#" + target);
      });

      btn.addEventListener("keydown", function (e) {
        var list = Array.prototype.slice.call(buttons);
        var i = list.indexOf(btn);
        var next = e.key === "ArrowRight" ? i + 1 : e.key === "ArrowLeft" ? i - 1 : -1;
        if (next >= 0 && next < list.length) {
          e.preventDefault();
          list[next].focus();
          list[next].click();
        }
      });
    });
  });

  /* open a tab directly from the URL hash */
  function selectTabFromHash() {
    if (!location.hash) return;
    var panel = document.querySelector(location.hash);
    if (panel && panel.classList.contains("tab-panel")) {
      var btn = document.querySelector('[aria-controls="' + panel.id + '"]');
      if (btn) btn.click();
    }
  }
  selectTabFromHash();
  window.addEventListener("hashchange", selectTabFromHash);

  /* --------------------------------------------------------- forms ------ */
  document.querySelectorAll("form[data-demo-form]").forEach(function (form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      if (!form.checkValidity()) {
        form.reportValidity();
        return;
      }
      var status = form.querySelector(".form-status");
      if (status) {
        status.classList.add("is-visible");
        status.setAttribute("role", "status");
        status.focus && status.focus();
      }
      form.reset();
    });
  });

  /* ---------------------------------------------------- footer year ----- */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = String(new Date().getFullYear());
  });

  /* ------------------------------------------ pause ticker off-screen --- */
  var tickers = document.querySelectorAll(".ticker");
  if (tickers.length && "IntersectionObserver" in window) {
    var tio = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        en.target.style.animationPlayState = "";
        var track = en.target.querySelector(".ticker__track");
        if (track) track.style.animationPlayState = en.isIntersecting ? "running" : "paused";
      });
    }, { threshold: 0 });
    tickers.forEach(function (t) { tio.observe(t); });
  }
})();
