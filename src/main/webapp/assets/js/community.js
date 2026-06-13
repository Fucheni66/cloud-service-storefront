// 开发者社区前台渲染：
//  - developer-community.jsp        问答列表 + 精选教程
//  - community-question-detail.jsp  问答详情 + 回复 + 发表评论
//  - community-publish.jsp          发表问答（提交到后台待审核）
// 数据来自 /api/community/*，由后台「开发者社区 / 精选教程」管理。
(function () {
  // 角标 → 配色（类名均已在预编译 CSS 中）
  var TAG_CLASS = {
    '连接': 'bg-blue-50 text-primary',
    '计费': 'bg-green-50 text-green-600',
    '网络': 'bg-indigo-50 text-indigo-600',
    '分享': 'bg-emerald-50 text-emerald-600',
    '教程': 'bg-orange-50 text-orange-600'
  };

  function api(path, options) {
    return fetch(path, Object.assign({ headers: { 'Accept': 'application/json' } }, options || {}))
      .then(function (r) { return r.json().catch(function () { return { success: false }; }); });
  }

  function postJson(path, body) {
    return api(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(body)
    });
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) { node.className = className; }
    if (text != null) { node.textContent = text; }
    return node;
  }

  function tagClass(tag) {
    return TAG_CLASS[tag] || 'bg-blue-50 text-primary';
  }

  // ================= 问答列表 =================
  function initList(listEl) {
    api('/api/community/questions').then(function (res) {
      var questions = (res && res.questions) || [];
      listEl.innerHTML = '';
      if (!questions.length) {
        listEl.appendChild(el('div', 'border border-gray-200 rounded-lg p-4 text-sm text-gray-400', '暂无问答，点击右上角「发表」分享你的问题或经验。'));
      } else {
        questions.forEach(function (q) { listEl.appendChild(renderListItem(q)); });
      }
    });

    var tutEl = document.getElementById('community-tutorials');
    if (tutEl) { initTutorials(tutEl); }

    applySupportInfo();
  }

  // 技术支持卡片时效由后台「系统设置·站点」配置，读取 /api/site 填充
  function applySupportInfo() {
    if (!document.getElementById('support-ticket-hours')) { return; }
    api('/api/site').then(function (res) {
      if (!res || res.success === false) { return; }
      var s = res.support || {};
      setText('support-ticket-hours', s.ticketHours);
      setText('support-fault', s.fault);
      setText('support-reply', s.reply);
    });
  }

  function setText(id, value) {
    if (!value) { return; }
    var node = document.getElementById(id);
    if (node) { node.textContent = value; }
  }

  function renderListItem(q) {
    var article = el('article', 'border border-gray-200 rounded-lg p-4 hover:border-primary hover:bg-blue-50 transition');
    var a = el('a', 'flex items-start gap-3');
    a.href = 'community-question-detail.jsp?question=' + encodeURIComponent(q.slug);

    if (q.tag) {
      a.appendChild(el('span', 'mt-0.5 text-xs font-medium px-2 py-1 rounded ' + tagClass(q.tag), q.tag));
    }

    var mid = el('div', 'flex-1');
    mid.appendChild(el('h3', 'font-bold text-gray-900', q.title));
    mid.appendChild(el('p', 'text-sm text-gray-500 mt-1', q.summary || ''));
    var meta = el('div', 'flex items-center gap-4 text-xs text-gray-400 mt-3');
    meta.appendChild(el('span', null, q.category || ''));
    meta.appendChild(el('span', null, (q.replyCount || 0) + ' 个回复'));
    meta.appendChild(el('span', null, q.createdAt || ''));
    mid.appendChild(meta);
    a.appendChild(mid);

    var icon = document.createElement('i');
    icon.className = 'fa-solid fa-angle-right text-gray-300 mt-1';
    a.appendChild(icon);

    article.appendChild(a);
    return article;
  }

  // 精选教程 = 产品动态中 tutorial 分类的文章（统一在「产品动态」后台维护）
  function initTutorials(tutEl) {
    api('/api/dynamics?category=tutorial').then(function (res) {
      var posts = (res && res.posts) || [];
      tutEl.innerHTML = '';
      if (!posts.length) {
        tutEl.appendChild(el('p', 'text-sm text-gray-400 py-4', '暂无教程。'));
        return;
      }
      posts.forEach(function (t) {
        var article = el('article', 'py-4');
        var link = el('a', 'block group');
        link.href = 'product-dynamics-detail.jsp?id=' + encodeURIComponent(t.slug);
        link.appendChild(el('h3', 'font-bold text-gray-900 group-hover:text-primary transition', t.title));
        link.appendChild(el('p', 'text-sm text-gray-500 mt-1', t.summary || ''));
        link.appendChild(el('span', 'block text-xs text-gray-400 mt-2', t.publishedAt || ''));
        article.appendChild(link);
        tutEl.appendChild(article);
      });
    });
  }

  // ================= 问答详情 =================
  function initDetail(detailEl) {
    var params = new URLSearchParams(window.location.search);
    var slug = params.get('question') || 'public-ip';

    api('/api/community/question?slug=' + encodeURIComponent(slug)).then(function (res) {
      if (!res || !res.success || !res.question) {
        detailEl.innerHTML = '';
        detailEl.appendChild(el('div', 'bg-white border border-gray-200 rounded-lg p-6 text-gray-500 text-sm', '该问答不存在或未发布。'));
        return;
      }
      renderDetail(detailEl, res.question, slug);
    });

    renderRelated(slug);
  }

  function renderDetail(detailEl, q, slug) {
    detailEl.innerHTML = '';
    var article = el('article', 'bg-white border border-gray-200 rounded-lg p-6');

    var headRow = el('div', 'flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-5');
    var headLeft = el('div');
    if (q.tag) {
      headLeft.appendChild(el('span', 'inline-flex items-center text-xs font-medium px-2 py-1 rounded ' + tagClass(q.tag), q.tag));
    }
    headLeft.appendChild(el('h2', 'text-2xl font-bold text-gray-900 mt-3', q.title));
    var meta = el('div', 'flex flex-wrap items-center gap-4 text-xs text-gray-400 mt-3');
    meta.appendChild(el('span', null, q.category || ''));
    meta.appendChild(el('span', null, (q.replyCount || 0) + ' 个回复'));
    meta.appendChild(el('span', null, q.createdAt || ''));
    headLeft.appendChild(meta);
    headRow.appendChild(headLeft);
    article.appendChild(headRow);

    var body = el('div', 'prose max-w-none text-gray-600 text-sm leading-7');
    String(q.content || '').split(/\n{2,}/).forEach(function (para) {
      var t = para.trim();
      if (t) { body.appendChild(el('p', null, t)); }
    });
    article.appendChild(body);

    if (q.recommendation) {
      var rec = el('div', 'mt-6 bg-blue-50 border border-blue-100 rounded-lg p-4');
      rec.appendChild(el('div', 'font-bold text-gray-900 mb-2', '推荐处理'));
      rec.appendChild(el('p', 'text-sm text-gray-600 leading-6', q.recommendation));
      article.appendChild(rec);
    }

    // 回复区
    var replyWrap = el('div', 'mt-6 border-t border-gray-100 pt-6');
    var replyHead = el('div', 'flex items-center justify-between gap-3 mb-4');
    replyHead.appendChild(el('h3', 'font-bold text-gray-900', '社区回复'));
    var countEl = el('span', 'text-xs text-gray-400', (q.replies ? q.replies.length : 0) + ' 条评论');
    replyHead.appendChild(countEl);
    replyWrap.appendChild(replyHead);

    var form = buildCommentForm(slug, countEl);
    replyWrap.appendChild(form.form);

    var list = el('div', 'space-y-5');
    (q.replies || []).forEach(function (r) { list.appendChild(renderReply(r)); });
    form.setList(list);
    replyWrap.appendChild(list);

    article.appendChild(replyWrap);
    detailEl.appendChild(article);
    document.title = (q.title || '问答详情') + ' - AJOU';
  }

  function renderReply(r) {
    var article = el('article', 'flex gap-3');
    var avatarText = r.official ? '支' : (r.authorName || '用').charAt(0);
    var avatarClass = r.official
      ? 'w-9 h-9 rounded-full bg-blue-50 text-primary flex items-center justify-center text-sm font-bold flex-shrink-0'
      : 'w-9 h-9 rounded-full bg-gray-100 text-gray-600 flex items-center justify-center text-sm font-bold flex-shrink-0';
    article.appendChild(el('div', avatarClass, avatarText));

    var main = el('div', 'flex-1 border-b border-gray-100 pb-5');
    var line = el('div', 'flex flex-wrap items-center gap-2 text-sm');
    line.appendChild(el('span', 'font-medium text-gray-900', r.authorName || '社区用户'));
    if (r.official) {
      line.appendChild(el('span', 'bg-blue-50 text-primary text-xs px-2 py-0.5 rounded', '官方'));
    }
    line.appendChild(el('span', 'text-xs text-gray-400', r.createdAt || '刚刚'));
    main.appendChild(line);
    main.appendChild(el('p', 'text-sm text-gray-600 mt-2 leading-6', r.content || ''));

    var actions = el('div', 'flex items-center gap-4 text-xs text-gray-400 mt-3');
    var like = el('button', 'hover:text-primary');
    like.type = 'button';
    like.innerHTML = '<i class="fa-regular fa-thumbs-up mr-1"></i>' + (r.likeCount || 0);
    var reply = el('button', 'hover:text-primary');
    reply.type = 'button';
    reply.innerHTML = '<i class="fa-regular fa-comment mr-1"></i>回复';
    actions.appendChild(like);
    actions.appendChild(reply);
    main.appendChild(actions);

    article.appendChild(main);
    return article;
  }

  function buildCommentForm(slug, countEl) {
    var listRef = { node: null };
    var form = el('form', 'flex items-start gap-3 mb-5');
    form.innerHTML =
      '<div class="w-9 h-9 rounded-full bg-primary text-white flex items-center justify-center text-sm font-bold flex-shrink-0">我</div>' +
      '<div class="flex-1">' +
      '  <textarea data-comment-input rows="3" placeholder="写下你的评论..." class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary resize-y"></textarea>' +
      '  <div class="flex justify-end mt-2">' +
      '    <button type="submit" class="bg-primary hover:bg-primary-hover text-white px-4 py-2 rounded text-sm font-medium transition">发表评论</button>' +
      '  </div>' +
      '</div>';

    form.addEventListener('submit', function (event) {
      event.preventDefault();
      var input = form.querySelector('[data-comment-input]');
      var content = input.value.trim();
      if (!content) { input.focus(); return; }

      var submitBtn = form.querySelector('button[type="submit"]');
      submitBtn.disabled = true;

      postJson('/api/community/reply', { slug: slug, content: content }).then(function (res) {
        submitBtn.disabled = false;
        if (!res || !res.success) {
          alert((res && res.message) || '评论提交失败，请稍后再试。');
          return;
        }
        if (listRef.node) {
          listRef.node.insertBefore(renderReply(res.reply), listRef.node.firstChild);
        }
        if (countEl) { countEl.textContent = (res.replyCount || 0) + ' 条评论'; }
        input.value = '';
      }).catch(function () {
        submitBtn.disabled = false;
        alert('网络错误，评论提交失败。');
      });
    });

    return { form: form, setList: function (node) { listRef.node = node; } };
  }

  function renderRelated(currentSlug) {
    var box = document.getElementById('community-related');
    if (!box) { return; }
    api('/api/community/questions').then(function (res) {
      var questions = (res && res.questions) || [];
      box.innerHTML = '';
      // 排除当前问题后最多显示 5 条
      questions.filter(function (q) { return q.slug !== currentSlug; }).slice(0, 5).forEach(function (q) {
        var a = el('a',
          'block border border-gray-200 rounded p-3 hover:border-primary hover:bg-blue-50 transition',
          q.title);
        a.href = 'community-question-detail.jsp?question=' + encodeURIComponent(q.slug);
        box.appendChild(a);
      });
    });
  }

  // ================= 发表问答 =================
  function initPublish(form) {
    form.addEventListener('submit', function (event) {
      event.preventDefault();
      var successEl = document.getElementById('publish-success');
      var body = {
        type: val('publish-type'),
        title: val('publish-title'),
        category: val('publish-category'),
        content: val('publish-content'),
        contact: val('publish-contact')
      };
      if (!body.title.trim() || !body.content.trim()) {
        alert('请填写标题和正文。');
        return;
      }
      var submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn) { submitBtn.disabled = true; }

      postJson('/api/community/publish', body).then(function (res) {
        if (submitBtn) { submitBtn.disabled = false; }
        if (!res || !res.success) {
          alert((res && res.message) || '提交失败，请稍后再试。');
          return;
        }
        if (successEl) {
          successEl.textContent = res.message || '内容已提交，待审核通过后将在社区问答中展示。';
          successEl.classList.remove('hidden');
        }
        form.reset();
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }).catch(function () {
        if (submitBtn) { submitBtn.disabled = false; }
        alert('网络错误，提交失败。');
      });
    });
  }

  function val(id) {
    var node = document.getElementById(id);
    return node ? node.value : '';
  }

  document.addEventListener('DOMContentLoaded', function () {
    var listEl = document.getElementById('community-list');
    if (listEl) { initList(listEl); return; }

    var detailEl = document.getElementById('community-detail');
    if (detailEl) { initDetail(detailEl); return; }

    var publishForm = document.getElementById('community-publish-form');
    if (publishForm) { initPublish(publishForm); }
  });
})();
