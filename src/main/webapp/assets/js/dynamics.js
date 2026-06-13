// 产品动态前台渲染：列表页(product-dynamics.jsp) 与详情页(product-dynamics-detail.jsp)
// 数据来自 /api/dynamics（含 posts 与 categories），由后台「产品动态 / 动态分类」管理。
(function () {
  // 配色键 → 角标 class（与后端 CategoryColor 保持一致；类名均已在预编译 CSS 中）
  var COLOR = {
    blue:    'bg-blue-50 text-primary border border-blue-100',
    green:   'bg-green-50 text-green-600 border border-green-200',
    orange:  'bg-orange-50 text-orange-600 border border-orange-100',
    red:     'bg-red-50 text-red-500 border border-red-200',
    indigo:  'bg-indigo-50 text-indigo-600 border border-indigo-100',
    slate:   'bg-slate-50 text-slate-600 border border-slate-200',
    emerald: 'bg-emerald-50 text-emerald-600 border border-emerald-100',
    gray:    'bg-gray-50 text-gray-600 border border-gray-200'
  };

  function badgeClass(color) {
    return COLOR[color] || COLOR.blue;
  }

  function api(path) {
    return fetch(path, { headers: { 'Accept': 'application/json' } }).then(function (r) {
      return r.json().catch(function () { return { success: false }; });
    });
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) { node.className = className; }
    if (text != null) { node.textContent = text; }
    return node;
  }

  function badgeSpan(color, label) {
    return el('span', 'inline-flex items-center text-xs font-medium px-2 py-1 rounded ' + badgeClass(color), label);
  }

  // ---------------- 列表页 ----------------
  var defaultKey = 'release';

  function initList(listEl) {
    api('/api/dynamics').then(function (res) {
      var posts = (res && res.posts) || [];
      var categories = (res && res.categories) || [];
      if (categories.length) { defaultKey = categories[0].code; }

      renderNav(categories);

      listEl.innerHTML = '';
      if (!posts.length) {
        listEl.appendChild(el('div', 'bg-white border border-gray-200 rounded-lg p-6 text-gray-400 text-sm', '暂无动态内容。'));
      } else {
        posts.forEach(function (p) { listEl.appendChild(renderCard(p)); });
      }
      bindTabs();
    });
  }

  function renderNav(categories) {
    var nav = document.getElementById('dynamics-categories');
    if (!nav) { return; }
    nav.innerHTML = '';
    categories.forEach(function (c) {
      var a = el('a', 'flex items-center justify-between px-3 py-2 rounded text-gray-600 hover:bg-gray-50 hover:text-primary');
      a.href = 'product-dynamics.jsp#' + c.code;
      a.setAttribute('data-dynamics-tab', c.code);
      a.appendChild(el('span', null, c.name));
      var i = document.createElement('i');
      i.className = 'fa-solid fa-angle-right text-xs';
      a.appendChild(i);
      nav.appendChild(a);
    });
  }

  function renderCard(p) {
    var article = el('article', 'bg-white border border-gray-200 rounded-lg p-6 hover:border-primary transition');
    article.setAttribute('data-dynamics-panel', p.category);

    var head = el('div', 'flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-4');
    var left = el('div');
    left.appendChild(badgeSpan(p.color, p.badgeText || p.categoryLabel));
    left.appendChild(el('h2', 'text-xl font-bold text-gray-900 mt-3', p.title));
    head.appendChild(left);
    head.appendChild(el('time', 'text-sm text-gray-400 whitespace-nowrap', p.publishedAt || ''));
    article.appendChild(head);

    article.appendChild(el('p', 'text-gray-500 leading-relaxed mb-4', p.summary || ''));

    var link = el('a', 'text-primary hover:text-primary-hover text-sm font-medium');
    link.href = 'product-dynamics-detail.jsp?id=' + encodeURIComponent(p.slug);
    link.innerHTML = '查看详情 <i class="fa-solid fa-arrow-right ml-1 text-xs"></i>';
    article.appendChild(link);
    return article;
  }

  // 左侧分类 Tab 过滤
  function bindTabs() {
    var tabs = document.querySelectorAll('[data-dynamics-tab]');
    var panels = document.querySelectorAll('[data-dynamics-panel]');

    function getActiveKey() {
      var hashKey = window.location.hash.replace('#', '');
      var hasPanel = Array.prototype.some.call(panels, function (panel) {
        return panel.dataset.dynamicsPanel === hashKey;
      });
      var hasTab = Array.prototype.some.call(tabs, function (tab) {
        return tab.dataset.dynamicsTab === hashKey;
      });
      return (hasPanel || hasTab) ? hashKey : defaultKey;
    }

    function setTabState(tab, isActive) {
      tab.classList.toggle('bg-blue-50', isActive);
      tab.classList.toggle('text-primary', isActive);
      tab.classList.toggle('font-medium', isActive);
      tab.classList.toggle('text-gray-600', !isActive);
      tab.classList.toggle('hover:bg-gray-50', !isActive);
      tab.classList.toggle('hover:text-primary', !isActive);
    }

    function render() {
      var activeKey = getActiveKey();
      tabs.forEach(function (tab) { setTabState(tab, tab.dataset.dynamicsTab === activeKey); });
      panels.forEach(function (panel) {
        panel.classList.toggle('hidden', panel.dataset.dynamicsPanel !== activeKey);
      });
    }

    tabs.forEach(function (tab) {
      tab.addEventListener('click', function (event) {
        event.preventDefault();
        var href = tab.getAttribute('href') || '#';
        var nextHash = href.indexOf('#') >= 0 ? '#' + href.split('#').pop() : href;
        if (window.location.hash !== nextHash) {
          history.pushState(null, '', nextHash);
        }
        render();
      });
    });

    window.addEventListener('hashchange', render);
    window.addEventListener('popstate', render);
    render();
  }

  // ---------------- 详情页 ----------------
  function initDetail(detailEl) {
    var params = new URLSearchParams(window.location.search);
    var slug = params.get('id') || '';

    api('/api/dynamics?slug=' + encodeURIComponent(slug)).then(function (res) {
      if (!res || !res.success || !res.post) {
        detailEl.innerHTML = '';
        detailEl.appendChild(el('div', 'bg-white border border-gray-200 rounded-lg p-6 text-gray-500 text-sm', '该动态不存在或未发布。'));
        return;
      }
      renderDetail(detailEl, res.post);
      renderRelated(res.related || [], slug);
    });
  }

  function renderDetail(detailEl, p) {
    detailEl.innerHTML = '';
    var article = el('article', 'bg-white border border-gray-200 rounded-lg p-6');

    var headWrap = el('div', 'mb-5');
    headWrap.appendChild(badgeSpan(p.color, p.badgeText || p.categoryLabel));
    headWrap.appendChild(el('h2', 'text-2xl font-bold text-gray-900 mt-3', p.title));
    var meta = el('div', 'flex flex-wrap items-center gap-4 text-xs text-gray-400 mt-3');
    if (p.publishedAt) { meta.appendChild(el('span', null, '发布日期：' + p.publishedAt)); }
    if (p.productScope) { meta.appendChild(el('span', null, p.productScope)); }
    headWrap.appendChild(meta);
    article.appendChild(headWrap);

    var body = el('div', 'prose max-w-none text-gray-600 text-sm leading-7');
    String(p.content || '').split(/\n{2,}/).forEach(function (para) {
      var t = para.trim();
      if (t) { body.appendChild(el('p', null, t)); }
    });
    article.appendChild(body);

    detailEl.appendChild(article);
    document.title = (p.title || '产品动态详情') + ' - AJOU';
  }

  function renderRelated(related, currentSlug) {
    var box = document.getElementById('dynamics-related');
    if (!box) { return; }
    box.innerHTML = '';
    // 排除当前文章后最多显示 5 条
    related.filter(function (r) { return r.slug !== currentSlug; }).slice(0, 5).forEach(function (r) {
      var a = el('a',
        'block border border-gray-200 rounded p-3 hover:border-primary hover:bg-blue-50 transition',
        r.title);
      a.href = 'product-dynamics-detail.jsp?id=' + encodeURIComponent(r.slug);
      box.appendChild(a);
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var listEl = document.getElementById('dynamics-list');
    if (listEl) { initList(listEl); return; }
    var detailEl = document.getElementById('dynamics-detail');
    if (detailEl) { initDetail(detailEl); }
  });
})();
