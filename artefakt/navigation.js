<script>
(function () {
  "use strict";

  var sektionen = Array.prototype.slice.call(
    document.querySelectorAll(".section.level2, .section")
  );
  if (!sektionen.length) {
    sektionen = Array.prototype.slice.call(document.querySelectorAll("body > div"));
  }

  var zaehler = document.createElement("div");
  zaehler.className = "slide-counter";
  zaehler.setAttribute("aria-live", "polite");
  document.body.appendChild(zaehler);

  function indexAktuell() {
    var y = window.scrollY || window.pageYOffset || 0;
    var mitte = y + window.innerHeight * 0.45;
    var idx = 0;
    for (var i = 0; i < sektionen.length; i += 1) {
      var oben = sektionen[i].offsetTop;
      if (oben <= mitte) {
        idx = i;
      }
    }
    return idx;
  }

  function anzeigeAktualisieren() {
    zaehler.textContent = (indexAktuell() + 1) + " / " + sektionen.length;
  }

  function springeZu(i) {
    if (i < 0) {
      i = 0;
    }
    if (i >= sektionen.length) {
      i = sektionen.length - 1;
    }
    sektionen[i].scrollIntoView({ behavior: "smooth", block: "start" });
    window.setTimeout(anzeigeAktualisieren, 350);
  }

  function istEingabe(element) {
    if (!element) {
      return false;
    }
    var tag = element.tagName ? element.tagName.toLowerCase() : "";
    return tag === "input" || tag === "textarea" || tag === "select" || element.isContentEditable;
  }

  document.addEventListener("keydown", function (event) {
    if (event.altKey || event.ctrlKey || event.metaKey || istEingabe(event.target)) {
      return;
    }
    var taste = event.key;
    if (taste === "ArrowDown" || taste === "ArrowRight" || taste === "PageDown" || taste === " ") {
      event.preventDefault();
      springeZu(indexAktuell() + 1);
    } else if (taste === "ArrowUp" || taste === "ArrowLeft" || taste === "PageUp") {
      event.preventDefault();
      springeZu(indexAktuell() - 1);
    } else if (taste === "Home") {
      event.preventDefault();
      springeZu(0);
    } else if (taste === "End") {
      event.preventDefault();
      springeZu(sektionen.length - 1);
    }
  }, { passive: false });

  var wartet = false;
  window.addEventListener("scroll", function () {
    if (wartet) {
      return;
    }
    wartet = true;
    window.requestAnimationFrame(function () {
      anzeigeAktualisieren();
      wartet = false;
    });
  }, { passive: true });

  window.addEventListener("resize", anzeigeAktualisieren);
  anzeigeAktualisieren();
})();
</script>
