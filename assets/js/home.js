// 首页热门产品从产品配置中读取，避免首页和产品页数据不一致。
$(function () {
  const config = window.PRODUCT_PAGE_CONFIG;

  if (!config) {
    return;
  }

  const products = config.sections.flatMap((section) => section.products).slice(0, 4);
  $('#home-hot-products').empty().append(products.map(renderHotProductCard));
});

function renderHotProductCard(product) {
  const card = $('<a>', {
    href: `purchase.html?instance=${encodeURIComponent(product.instance)}`,
    class: 'group rounded-lg p-4 hover:bg-gray-50 transition border border-transparent hover:border-gray-100',
  });

  const title = $('<div>', { class: 'flex items-center space-x-2 mb-2' }).append(
    $('<h4>', {
      class: 'font-bold text-gray-900 group-hover:text-primary transition',
      text: product.title,
    })
  );

  if (product.badge) {
    title.append($('<span>', {
      class: `${product.badge.className} text-[10px] px-1.5 py-0.5 rounded`,
      text: product.badge.text,
    }));
  }

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
