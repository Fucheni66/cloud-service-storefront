// 使用 jQuery 根据产品配置动态渲染产品列表页内容。
$(function () {
  const config = window.PRODUCT_PAGE_CONFIG;

  if (!config) {
    return;
  }

  $('#products-hero-title').text(config.hero.title);
  $('#products-hero-description').text(config.hero.description);

  $('#product-sections').empty().append(config.sections.map(renderSection));
});

function renderSection(section) {
  return $('<section>').append(
    $('<h2>', {
      class: `text-xl font-bold mb-6 text-gray-900 flex items-center ${section.headingClass}`.trim()
    }).append(
      $('<i>', {
        class: `${section.icon} ${section.iconClass} mr-2`
      }),
      ` ${section.title}`
    ),

    $('<div>', {
      class: `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 ${section.gridClass}`.trim()
    }).append(section.products.map((product) => renderProductCard(product, section)))
  )[0];
}

function renderProductCard(product, section) {
  const card = $('<article>', {
    class: `bg-white rounded-xl shadow-sm border border-gray-200 ${section.cardHoverClass} hover:shadow-md transition p-6 flex flex-col relative overflow-hidden`
  });

  if (product.badge) {
    card.append($('<div>', {
      class: `absolute top-0 right-0 ${product.badge.className} text-xs font-bold px-3 py-1 rounded-bl-lg`,
      text: product.badge.text
    }));
  }

  card.append(
    $('<div>', { class: 'mb-4' }).append(
      $('<h3>', { class: 'text-xl font-bold text-gray-900', text: product.title }),
      $('<p>', { class: 'text-sm text-gray-500 mt-1', text: product.description })
    ),

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

      $('<a>', {
        href: `purchase.html?instance=${encodeURIComponent(product.instance)}`,
        class: `${section.buttonClass} text-white px-5 py-2.5 rounded text-sm font-medium transition shadow-sm`,
        text: '立即配置'
      })
    )
  );

  return card[0];
}
