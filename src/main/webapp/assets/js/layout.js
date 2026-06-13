// 公共头部和底部加载：优先读取 templates 目录，直接打开 html 时使用备用模板。
(function ($) {
  if (!$) {
    return;
  }

  $(function () {
    loadTemplate($('#site-header'), 'templates/header.html', getHeaderTemplate(), function () {
      setActiveNav();

      if (window.renderAuthNav) {
        window.renderAuthNav();
      }
    });

    loadTemplate($('#site-footer'), 'templates/footer.html', getFooterTemplate(), applySiteConfig);
  });

  // 页脚联系方式由后台「系统设置·站点」配置，读取 /api/site 填充
  function applySiteConfig() {
    if (window.location.protocol === 'file:') {
      return;
    }
    $.ajax({ url: '/api/site', dataType: 'json' }).done(function (res) {
      if (!res || res.success === false) {
        return;
      }
      if (res.phone) {
        $('#footer-phone').text(res.phone);
      }
      if (res.email) {
        $('#footer-email').text(res.email);
      }
    });
  }

  function loadTemplate($target, path, fallbackHtml, callback) {
    if (!$target.length) {
      return;
    }

    // file:// 直接打开页面时，浏览器会阻止 jQuery load 读取本地 html 文件。
    if (window.location.protocol === 'file:') {
      $target.html(fallbackHtml);
      runCallback(callback);
      return;
    }

    $target.load(path, function (response, status) {
      // 非服务器环境、路径异常或模板请求失败时，使用 JS 中的备用模板。
      if (status === 'error') {
        $target.html(fallbackHtml);
      }

      runCallback(callback);
    });
  }

  function runCallback(callback) {
    if (typeof callback === 'function') {
      callback();
    }
  }

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
    const page = (window.location.pathname.split('/').pop() || 'index.jsp').toLowerCase();
    const hash = window.location.hash.replace('#', '');

    if (page === 'index.jsp' || page === '') {
      return 'home';
    }

    if (page === 'products.jsp' || page === 'purchase.jsp') {
      return 'products';
    }

    if (page === 'developer-community.jsp' || page === 'community-publish.jsp' || page === 'community-question-detail.jsp') {
      return 'community';
    }

    if (page === 'console.jsp' || page === 'console-manage.jsp') {
      return 'console';
    }

    if (page === 'product-dynamics.jsp' && hash === 'solution') {
      return 'solution';
    }

    if (page === 'product-dynamics.jsp' || page === 'product-dynamics-detail.jsp') {
      return 'dynamics';
    }

    return '';
  }

  function getHeaderTemplate() {
    return [
      '<nav class="site-main-nav">',
      '  <div class="site-nav-inner">',
      '    <div class="site-nav-row">',
      '      <div class="site-nav-left">',
      '        <a href="index.jsp" class="site-logo">',
      '          <i class="fa-solid fa-cloud site-logo-icon"></i>',
      '          <span class="site-logo-text">AJOU</span>',
      '        </a>',
      '        <div class="site-nav-links">',
      '          <a href="index.jsp" data-nav-key="home" class="site-nav-link">首页</a>',
      '          <a href="products.jsp" data-nav-key="products" class="site-nav-link">产品购买</a>',
      '          <a href="product-dynamics.jsp#solution" data-nav-key="solution" class="site-nav-link">解决方案</a>',
      '          <a href="developer-community.jsp" data-nav-key="community" class="site-nav-link">开发者社区</a>',
      '          <a href="product-dynamics.jsp" data-nav-key="dynamics" class="site-nav-link">产品动态</a>',
      '        </div>',
      '      </div>',
      '      <div class="site-nav-actions">',
      '        <a href="console.jsp" data-nav-key="console" class="site-console-link">控制台</a>',
      '        <a href="auth.jsp" class="site-login-link">登录 / 注册</a>',
      '      </div>',
      '    </div>',
      '  </div>',
      '</nav>',
    ].join('');
  }

  function getFooterTemplate() {
    return [
      '<footer id="footer" class="bg-gray-800 text-gray-300 py-10 mt-auto">',
      '  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 md:grid-cols-4 gap-8">',
      '    <div>',
      '      <h4 class="text-white font-bold mb-4">关于我们</h4>',
      '      <ul class="space-y-2 text-sm">',
      '        <li><a href="product-dynamics-detail.jsp?id=about-company" class="hover:text-white">公司简介</a></li>',
      '        <li><a href="product-dynamics-detail.jsp?id=about-news" class="hover:text-white">新闻动态</a></li>',
      '        <li><a href="product-dynamics-detail.jsp?id=about-contact" class="hover:text-white">联系我们</a></li>',
      '      </ul>',
      '    </div>',
      '    <div>',
      '      <h4 class="text-white font-bold mb-4">产品服务</h4>',
      '      <ul class="space-y-2 text-sm">',
      '        <li><a href="products.jsp" class="hover:text-white">云服务器 ECS</a></li>',
      '        <li><a href="products.jsp" class="hover:text-white">GPU 云服务器</a></li>',
      '        <li><a href="products.jsp" class="hover:text-white">云数据库 RDS</a></li>',
      '      </ul>',
      '    </div>',
      '    <div>',
      '      <h4 class="text-white font-bold mb-4">帮助支持</h4>',
      '      <ul class="space-y-2 text-sm">',
      '        <li><a href="product-dynamics-detail.jsp?id=support-help" class="hover:text-white">帮助中心</a></li>',
      '        <li><a href="product-dynamics-detail.jsp?id=support-api" class="hover:text-white">API 文档</a></li>',
      '        <li><a href="product-dynamics-detail.jsp?id=support-ticket" class="hover:text-white">提交工单</a></li>',
      '      </ul>',
      '    </div>',
      '    <div>',
      '      <h4 class="text-white font-bold mb-4">联系方式</h4>',
      '      <ul class="space-y-2 text-sm">',
      '        <li><i class="fa-solid fa-phone mr-2"></i> <span id="footer-phone">400-888-8888</span></li>',
      '        <li><i class="fa-solid fa-envelope mr-2"></i> <span id="footer-email">admin@example.com</span></li>',
      '      </ul>',
      '    </div>',
      '  </div>',
      '  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 pt-8 border-t border-gray-700 text-sm text-center">&copy; 2026 Ajou yanbo</div>',
      '</footer>',
    ].join('');
  }
})(window.jQuery);
