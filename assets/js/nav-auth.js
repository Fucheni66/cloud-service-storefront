// 公共导航登录状态渲染：使用 jQuery 把“登录 / 注册”替换成用户菜单。
(function ($) {
  if (!$) {
    return;
  }

  // 把函数挂到 window 上，layout.js 加载完 header.html 后可以直接调用它。
  window.renderAuthNav = renderAuthNav;

  // 页面 DOM 加载完成后先尝试渲染一次。
  $(renderAuthNav);

  // 点击菜单外部时关闭所有用户下拉菜单。
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

    // 公共头部模板里的登录入口保持 href="auth.html"，登录后统一替换成头像菜单。
    $('a[href="auth.html"]').each(function () {
      const $link = $(this);

      if (!$link.text().includes("登录")) {
        return;
      }

      $link.replaceWith(renderUserMenu(user));
    });
  }

  function renderUserMenu(user) {
    // 用户菜单外层，用于定位下拉框和判断点击区域。
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

    // 下拉菜单顶部展示当前用户，下面提供控制台入口和退出登录。
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
    // 用户摘要使用 text() 写入，避免把邮箱或名称当作 HTML 解析。
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
    // 退出登录只清理浏览器登录态；后端 JSON 登录记录保留作为历史记录。
    localStorage.removeItem("ajou_login_info");
    localStorage.removeItem("ajou_auth_user");
    localStorage.removeItem("ajou_auth_token");
    window.location.href = "index.html";
  }

  function getStoredUser() {
    // 优先读取精简用户信息；不存在时从完整登录返回值里取 user。
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
    // Google 用户通常带 picture 字段，优先显示真实头像。
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
