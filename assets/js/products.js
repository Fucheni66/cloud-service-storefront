// 使用 jQuery 根据产品配置动态渲染产品列表页内容。
$(function () {
  // 产品页数据由 assets/js/config/products.config.js 注入到 window 上。
  const config = window.PRODUCT_PAGE_CONFIG;

  // 配置缺失时直接停止渲染，避免页面脚本报错。
  if (!config) {
    return;
  }

  // 渲染产品页顶部标题和说明文案。
  $('#products-hero-title').text(config.hero.title);
  $('#products-hero-description').text(config.hero.description);
  // 根据配置里的 sections 渲染 CPU、GPU 等产品分区。
  $('#product-sections').empty().append(config.sections.map(renderSection));
});

function renderSection(section) {
  // 一个 section 对应一组产品，例如 CPU 云服务器或 GPU 云服务器。
  return $('<section>').append(
    $('<h2>', {
      class: `text-xl font-bold mb-6 text-gray-900 flex items-center ${section.headingClass}`.trim()
    }).append(
      $('<i>', {
        class: `${section.icon} ${section.iconClass} mr-2`
      }),
      ` ${section.title}`
    ),
    // 产品卡片使用响应式网格布局，具体列数和间距由 Tailwind class 控制。
    $('<div>', {
      class: `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 ${section.gridClass}`.trim()
    }).append(section.products.map((product) => renderProductCard(product, section)))
  )[0];
}

function renderProductCard(product, section) {
  // 每个商品卡片的悬停样式、按钮颜色等由所属 section 配置决定。
  const card = $('<article>', {
    class: `bg-white rounded-xl shadow-sm border border-gray-200 ${section.cardHoverClass} hover:shadow-md transition p-6 flex flex-col relative overflow-hidden`
  });

  if (product.badge) {
    // badge 用于展示“推荐”“热门”等标签，内容和颜色来自配置。
    card.append($('<div>', {
      class: `absolute top-0 right-0 ${product.badge.className} text-xs font-bold px-3 py-1 rounded-bl-lg`,
      text: product.badge.text
    }));
  }

  // 卡片主体包含标题、描述、规格列表、价格和购买入口。
  card.append(
    $('<div>', { class: 'mb-4' }).append(
      $('<h3>', { class: 'text-xl font-bold text-gray-900', text: product.title }),
      $('<p>', { class: 'text-sm text-gray-500 mt-1', text: product.description })
    ),
    // specs 数组逐项渲染，图标和文字都来自产品配置。
    $('<ul>', { class: 'text-sm text-gray-600 mb-8 flex-grow space-y-3' }).append(
      product.specs.map((spec) => $('<li>', { class: 'flex items-center' }).append(
        $('<i>', { class: `${spec.icon} w-6 text-gray-400` }),
        ` ${spec.text}`
      )[0])
    ),
    $('<div>', { class: 'border-t border-gray-100 pt-5 flex items-center justify-between mt-auto' }).append(
      $('<div>').append(
        $('<span>', { class: 'text-2xl font-bold text-[#FF6A00]', text: `¥${product.price}` }),
        $('<span>', { class: 'text-gray-500 text-sm', text: product.unit })
      ),
      // 点击“立即配置”进入购买页，并通过 instance 参数带上当前商品规格。
      $('<a>', {
        href: `purchase.html?instance=${encodeURIComponent(product.instance)}`,
        class: `${section.buttonClass} text-white px-5 py-2.5 rounded text-sm font-medium transition shadow-sm`,
        text: '立即配置'
      })
    )
  );

  return card[0];
}
