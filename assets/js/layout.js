// 公共头部和底部加载：页面只保留占位容器，模板由本地 jQuery load 引入。
(function ($) {
  if (!$) {
    return;
  }

  $(function () {
    $('#site-header').load('templates/header.html', function () {
      setActiveNav();

      if (window.renderAuthNav) {
        window.renderAuthNav();
      }
    });

    $('#site-footer').load('templates/footer.html');
  });

  function setActiveNav() {
    const activeKey = getActiveKey();

    $('.site-nav-link').each(function () {
      const link = $(this);
      const isActive = link.data('nav-key') === activeKey;

      link.toggleClass('is-active', isActive);
    });

    $('.site-console-link').toggleClass('is-active', activeKey === 'console');
  }

  function getActiveKey() {
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
