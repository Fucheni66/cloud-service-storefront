// 公共导航登录状态渲染：使用 jQuery 把“登录 / 注册”替换成用户菜单。
(function ($) {
  if (!$) {
    return;
  }

  window.renderAuthNav = renderAuthNav;

  $(renderAuthNav);

  $(document).on("click", function (event) {
    if ($(event.target).closest(".nav-auth-menu").length) {
      return;
    }

    closeOtherMenus(null);
  });

  function renderAuthNav() {
    const user = getStoredUser();

    if (!user) {
      return;
    }

    $('a[href="auth.html"]').each(function () {
      const $link = $(this);

      if (!$link.text().includes("登录")) {
        return;
      }

      $link.replaceWith(renderUserMenu(user));
    });
  }

  function renderUserMenu(user) {
    const $wrapper = $("<div>", {
      class: "relative nav-auth-menu",
    });

    const $button = $("<button>", {
      type: "button",
      class:
        "inline-flex items-center gap-2 max-w-[180px] rounded-full bg-white border border-gray-200 px-3 py-1.5 text-sm font-medium text-gray-700 hover:border-primary hover:text-primary transition shadow-sm",
      title: user.email || user.name || "已登录用户",
      "aria-haspopup": "true",
      "aria-expanded": "false",
    });

    $button
      .append(renderAvatar(user))
      .append(renderName(user))
      .append(renderChevron())
      .on("click", function (event) {
        event.stopPropagation();
        toggleMenu($wrapper, $button);
      });

    const $menu = $("<div>", {
      class:
        "hidden absolute right-0 mt-2 w-48 bg-white border border-gray-200 rounded-xl shadow-lg py-2 z-[80]",
      "data-nav-auth-dropdown": "true",
    });

    $menu
      .append(renderUserSummary(user))
      .append(renderMenuLink("查看主页", "console.html", "fa-solid fa-house"))
      .append(renderLogoutButton());

    return $wrapper.append($button, $menu);
  }

  function toggleMenu($wrapper, $button) {
    closeOtherMenus($wrapper);

    const $menu = $wrapper.find("[data-nav-auth-dropdown]");
    const isOpen = !$menu.hasClass("hidden");

    $menu.toggleClass("hidden", isOpen);
    $button.attr("aria-expanded", String(!isOpen));
  }

  function closeOtherMenus($currentWrapper) {
    const currentNode =
      $currentWrapper && $currentWrapper.length ? $currentWrapper[0] : null;

    $(".nav-auth-menu").each(function () {
      if (this === currentNode) {
        return;
      }

      const $wrapper = $(this);
      $wrapper.find("[data-nav-auth-dropdown]").addClass("hidden");
      $wrapper.find("button").attr("aria-expanded", "false");
    });
  }

  function renderUserSummary(user) {
    return $("<div>", {
      class: "px-4 pb-2 mb-2 border-b border-gray-100",
    }).append(
      $("<div>", {
        class: "text-sm font-semibold text-gray-900 truncate",
        text: user.name || "已登录用户",
      }),
      $("<div>", {
        class: "text-xs text-gray-500 truncate mt-0.5",
        text: user.email || "",
      }),
    );
  }

  function renderMenuLink(text, href, icon) {
    return $("<a>", {
      href: href,
      class:
        "flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-blue-50 hover:text-primary transition",
    }).append(
      $("<i>", {
        class: icon + " w-4 text-gray-400",
      }),
      $("<span>", {
        text: text,
      }),
    );
  }

  function renderLogoutButton() {
    return $("<button>", {
      type: "button",
      class:
        "w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition text-left",
    })
      .append(
        $("<i>", {
          class: "fa-solid fa-right-from-bracket w-4 text-red-400",
        }),
        $("<span>", {
          text: "退出登录",
        }),
      )
      .on("click", logout);
  }

  function logout() {
    localStorage.removeItem("ajou_login_info");
    localStorage.removeItem("ajou_auth_user");
    localStorage.removeItem("ajou_auth_token");
    window.location.href = "index.html";
  }

  function getStoredUser() {
    const directUser = readJson("ajou_auth_user");

    if (directUser && (directUser.name || directUser.email)) {
      return directUser;
    }

    const loginInfo = readJson("ajou_login_info");
    return loginInfo && loginInfo.user ? loginInfo.user : null;
  }

  function readJson(key) {
    try {
      return JSON.parse(localStorage.getItem(key) || "null");
    } catch (error) {
      return null;
    }
  }

  function renderAvatar(user) {
    if (user.picture) {
      return $("<img>", {
        src: user.picture,
        alt: user.name || user.email || "user",
        referrerPolicy: "no-referrer",
        class: "w-7 h-7 rounded-full object-cover flex-shrink-0",
      });
    }

    return $("<span>", {
      class:
        "w-7 h-7 rounded-full bg-primary text-white flex items-center justify-center text-xs font-bold flex-shrink-0",
      text: getInitial(user),
    });
  }

  function renderName(user) {
    return $("<span>", {
      class: "truncate",
      text: user.name || user.email || "已登录",
    });
  }

  function renderChevron() {
    return $("<i>", {
      class: "fa-solid fa-angle-down text-xs text-gray-400 flex-shrink-0",
    });
  }

  function getInitial(user) {
    const value = (user.name || user.email || "U").trim();
    return value ? value.charAt(0).toUpperCase() : "U";
  }
})(window.jQuery);
