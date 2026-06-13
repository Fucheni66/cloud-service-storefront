// 原为 Tailwind Play CDN 运行时引擎(~400KB JIT, 导致卡顿)，已替换为轻量加载器：
// 注入预编译静态 CSS，无运行时编译。页面 HTML 无需改动。
(function () {
  window.tailwind = window.tailwind || { config: {} }; // 兜底，避免 tailwind-config.js 报 ReferenceError
  document.write('<link rel="stylesheet" href="/assets/css/tailwind.css?v=precompiled-1">');
})();
