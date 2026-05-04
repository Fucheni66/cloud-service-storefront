// 首页热门产品从产品配置中读取，避免首页和产品页数据不一致。
$(function () {
  // 产品配置由 assets/js/config/products.config.js 注入到 window 上。
  const config = window.PRODUCT_PAGE_CONFIG;

  // 如果配置文件加载成功，就把首页顶部的热门产品渲染出来。
  if (config) {
    const products = config.sections.flatMap((section) => section.products).slice(0, 4);
    $('#home-hot-products').empty().append(products.map(renderHotProductCard));
  }

  // 不管配置是否加载成功，Tab 都可以点击切换。
  bindPopularProductTabs();
});

function bindPopularProductTabs() {
  // 简单三步：选中按钮，取消全部内容，显示当前内容。
  $('.popular-product-tab').on('click', function () {
    var target = $(this).data('popular-product-tab');

    $('.popular-product-tab').removeClass('active');
    $(this).addClass('active');

    $('.popular-product-panel').removeClass('active');
    $('[data-popular-product-panel="' + target + '"]').addClass('active');
  });
}

function renderHotProductCard(product) {
  // 每个热门产品卡片点击后进入购买页，并把实例规格带到 URL 参数中。
  const card = $('<a>', {
    href: `purchase.html?instance=${encodeURIComponent(product.instance)}`,
    class: 'group rounded-lg p-4 hover:bg-gray-50 transition border border-transparent hover:border-gray-100',
  });

  // 标题区域包含产品名称；如果配置了 badge，会在标题右侧追加标签。
  const title = $('<div>', { class: 'flex items-center space-x-2 mb-2' }).append(
    $('<h4>', {
      class: 'font-bold text-gray-900 group-hover:text-primary transition',
      text: product.title,
    })
  );

  if (product.badge) {
    // badge 的颜色和文案由配置文件控制，首页只负责渲染。
    title.append($('<span>', {
      class: `${product.badge.className} text-[10px] px-1.5 py-0.5 rounded`,
      text: product.badge.text,
    }));
  }

  // 卡片主体展示描述和价格，金额、单位都来自产品配置。
  card.append(
    title,
    $('<p>', {
      class: 'text-xs text-gray-500 mb-4 line-clamp-2 min-h-[32px]',
      text: product.description,
    }),
    $('<div>', { class: 'text-[#FF6A00]' }).append(
      $('<span>', { class: 'text-sm', text: '¥' }),
      $('<span>', { class: 'text-xl font-bold', text: product.price }),
      $('<span>', { class: 'text-xs text-gray-500 ml-1', text: product.unit })
    )
  );

  return card[0];
}
