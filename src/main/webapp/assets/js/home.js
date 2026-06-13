// 首页数据对接：顶部热门产品浮层、产品动态一条、热门产品推荐三标签。
// 数据来自 /api/home（hotProducts / recommend / dynamic），由后台「首页配置 / 首页推荐 / 产品规格」管理。
$(function () {
  bindPopularProductTabs();
  loadHome();
});

// 动态分类配色键 → 角标 class（与后端 CategoryColor 保持一致，类名均已在预编译 CSS 中）
var DYNAMIC_BADGE = {
  blue: 'border-blue-200 text-primary',
  green: 'border-green-200 text-green-600',
  orange: 'border-orange-200 text-orange-600',
  red: 'border-red-200 text-red-500',
  indigo: 'border-indigo-200 text-indigo-600',
  slate: 'border-slate-200 text-slate-600',
  emerald: 'border-emerald-200 text-emerald-600',
  gray: 'border-gray-200 text-gray-600'
};

function loadHome() {
  $.ajax({ url: '/api/home', dataType: 'json' })
    .done(function (res) {
      if (!res || res.success === false) {
        return;
      }
      renderHotProducts(res.hotProducts || []);
      renderRecommend(res.recommend || {});
      renderDynamic(res.dynamic || null);
    });
}

function bindPopularProductTabs() {
  $('.popular-product-tab').on('click', function () {
    var target = $(this).data('popular-product-tab');

    $('.popular-product-tab').removeClass('active');
    $(this).addClass('active');

    $('.popular-product-panel').removeClass('active');
    $('[data-popular-product-panel="' + target + '"]').addClass('active');
  });
}

// ---------------- 顶部热门产品浮层 ----------------
function renderHotProducts(products) {
  var $box = $('#home-hot-products');
  if (!$box.length) { return; }
  $box.empty();
  if (!products.length) {
    $box.append($('<div>', { class: 'text-sm text-gray-400 col-span-full', text: '暂无热门产品，请在后台配置首页权重。' }));
    return;
  }
  $box.append(products.map(renderHotProductCard));
}

function renderHotProductCard(product) {
  var card = $('<a>', {
    href: 'purchase.jsp?instance=' + encodeURIComponent(product.instanceCode || ''),
    class: 'group rounded-lg p-4 hover:bg-gray-50 transition border border-transparent hover:border-gray-100'
  });

  var title = $('<div>', { class: 'flex items-center space-x-2 mb-2' }).append(
    $('<h4>', {
      class: 'font-bold text-gray-900 group-hover:text-primary transition',
      text: product.title
    })
  );

  if (product.badge) {
    title.append($('<span>', {
      class: (product.gpu ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-primary') + ' text-[10px] px-1.5 py-0.5 rounded',
      text: product.badge
    }));
  }

  card.append(
    title,
    $('<p>', {
      class: 'text-xs text-gray-500 mb-4 line-clamp-2 min-h-[32px]',
      text: product.description || ''
    }),
    $('<div>', { class: 'text-[#FF6A00]' }).append(
      $('<span>', { class: 'text-sm', text: '¥' }),
      $('<span>', { class: 'text-xl font-bold', text: product.price }),
      $('<span>', { class: 'text-xs text-gray-500 ml-1', text: product.unit || '/月起' })
    )
  );

  return card[0];
}

// ---------------- 热门产品推荐三标签 ----------------
function renderRecommend(recommend) {
  ['basic', 'business', 'gpu'].forEach(function (tab) {
    var $panel = $('#recommend-' + tab);
    if (!$panel.length) { return; }
    var cards = recommend[tab] || [];
    $panel.empty();
    if (!cards.length) {
      $panel.append($('<div>', { class: 'text-sm text-gray-400', text: '该分类暂无推荐，请在后台「首页推荐」中添加。' }));
      return;
    }
    $panel.append(cards.map(renderRecommendCard));
  });
}

function renderRecommendCard(card) {
  var isGpu = !!card.gpu;
  var accent = isGpu ? 'text-purple-600' : 'text-primary';
  var article = $('<article>', {
    class: 'border border-gray-200 rounded-lg p-6 hover:shadow-lg transition bg-white ' +
      (isGpu ? 'hover:border-purple-500' : 'hover:border-primary')
  });

  article.append(
    $('<div>', { class: accent + ' text-2xl mb-5' }).append(
      $('<i>', { class: card.icon || 'fa-solid fa-server' })
    ),
    $('<h3>', { class: 'text-lg font-bold text-gray-900 mb-2', text: card.title }),
    $('<p>', { class: 'text-sm text-gray-500 leading-6 min-h-[72px]', text: card.description || '' })
  );

  if (card.spec) {
    article.append($('<div>', { class: 'mt-5 text-sm text-gray-600', text: '推荐：' + card.spec }));
  }

  if (card.price) {
    article.append(
      $('<div>', { class: 'mt-4 text-[#FF6A00]' }).append(
        $('<span>', { class: 'text-sm', text: '¥' }),
        $('<span>', { class: 'text-2xl font-bold', text: card.price }),
        $('<span>', { class: 'text-xs text-gray-500 ml-1', text: card.unit || '/月起' })
      )
    );
  }

  var buy = $('<a>', {
    href: 'purchase.jsp?instance=' + encodeURIComponent(card.instance || ''),
    class: 'mt-5 inline-flex items-center text-sm font-medium ' +
      (isGpu ? 'text-purple-600 hover:text-purple-700' : 'text-primary hover:text-primary-hover')
  });
  buy.html('立即选购 <i class="fa-solid fa-arrow-right ml-2 text-xs"></i>');
  article.append(buy);

  return article[0];
}

// ---------------- 产品动态一条 ----------------
function renderDynamic(dynamic) {
  var $box = $('#home-dynamic');
  if (!$box.length) { return; }
  $box.empty();

  $box.append(
    $('<span>', {
      class: 'font-bold text-primary mr-3 border-r border-gray-300 pr-3 flex-shrink-0',
      text: '产品动态'
    })
  );

  if (!dynamic) {
    $box.attr('href', 'product-dynamics.jsp');
    $box.append($('<span>', { class: 'truncate text-gray-400', text: '暂无产品动态' }));
    return;
  }

  $box.attr('href', 'product-dynamics-detail.jsp?id=' + encodeURIComponent(dynamic.slug || ''));

  var label = dynamic.badgeText || dynamic.categoryLabel;
  if (label) {
    var badgeClass = DYNAMIC_BADGE[dynamic.color] || DYNAMIC_BADGE.blue;
    $box.append($('<span>', {
      class: 'border ' + badgeClass + ' px-1 text-xs rounded mr-2 flex-shrink-0',
      text: label
    }));
  }

  $box.append($('<span>', { class: 'truncate', text: dynamic.title || '' }));
}
