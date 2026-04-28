// 公共头部和底部加载：页面只保留占位容器，模板由本地 jQuery load 引入。
(function ($) {
  // 如果 jQuery 没有加载成功，直接退出，避免后续页面脚本报错。
  if (!$) {
    return;
  }

  // 等页面 DOM 就绪后，再把公共 HTML 模板插入到占位容器中。
  $(function () {
    // 加载公共头部模板。加载完成后再设置当前导航高亮和登录状态。
    $('#site-header').load('templates/header.html', function () {
      setActiveNav();

      // 头部已经插入页面后，直接调用 nav-auth.js 暴露出来的登录状态渲染函数。
      if (window.renderAuthNav) {
        window.renderAuthNav();
      }
    });

    // 加载公共底部模板。底部没有额外交互，直接插入即可。
    $('#site-footer').load('templates/footer.html');
  });

  function setActiveNav() {
    // 根据当前页面地址计算应该高亮哪个导航项。
    const activeKey = getActiveKey();

    $('.site-nav-link').each(function () {
      const link = $(this);
      const isActive = link.data('nav-key') === activeKey;

      // 当前页面对应的导航项显示主色下划线。
      link.toggleClass('is-active', isActive);
    });

    // 控制台入口不在普通导航列表里，所以单独处理高亮状态。
    $('.site-console-link').toggleClass('is-active', activeKey === 'console');
  }

  function getActiveKey() {
    // page 用于判断当前 HTML 文件，hash 用于区分产品动态里的解决方案分类。
    const page = (window.location.pathname.split('/').pop() || 'index.html').toLowerCase();
    const hash = window.location.hash.replace('#', '');

    if (page === 'index.html' || page === '') {
      return 'home';
    }

    if (page === 'products.html' || page === 'purchase.html') {
      return 'products';
    }

    if (page === 'developer-community.html' || page === 'community-publish.html' || page === 'community-question-detail.html') {
      return 'community';
    }

    if (page === 'console.html' || page === 'console-manage.html') {
      return 'console';
    }

    if (page === 'product-dynamics.html' && hash === 'solution') {
      return 'solution';
    }

    if (page === 'product-dynamics.html' || page === 'product-dynamics-detail.html') {
      return 'dynamics';
    }

    return '';
  }
})(window.jQuery);
