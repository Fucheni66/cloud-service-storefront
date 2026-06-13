// AI 自动导购：右侧悬浮球 + 对话框 + 假鼠标自动选购。
// - 对话经 /api/ai/chat 后端代理调用大模型（后台「系统设置 · AI 大模型」配置，密钥不出后端）
// - 模型给出推荐(action)后展示「让 AI 自动下单」按钮，点击生成跨页执行计划
// - 计划与会话存 sessionStorage：页面跳转刷新后脚本恢复状态继续执行（无需 iframe）
// - 假鼠标 = 半透明圆形背景 + 指针图标，平滑移动到目标元素并触发真实点击
(function () {
  'use strict';

  var CHAT_KEY = 'ajou_ai_chat';
  var PLAN_KEY = 'ajou_ai_plan';
  var API = '/api/ai/chat';

  var chat = load(CHAT_KEY) || { open: false, messages: [] };
  var sending = false;

  // 问题类快捷提示库（对应已有解决方案/官方回复，便于命中跳转），每次加载随机取一条
  var PROBLEM_HINTS = [
    '我的服务器 SSH 连不上一直超时怎么办？',
    'GPU 实例怎么安装 NVIDIA 驱动和 CUDA？',
    '网站访问量上来后变慢，怎么扩容？',
    '数据库要不要和应用部署在同一台服务器？',
    '云服务器的数据怎么做备份和快照？',
    '按量计费和包年包月该怎么选？',
    '服务器无法重置系统怎么处理？',
    '怎么配置安全组只开放指定端口？'
  ];
  var productMap = null; // 实时在售规格（来自 /api/products），用于校验/识别 AI 推荐的规格

  // 实时拉取在售产品规格，保证后台新增的配置在自动选购时也能被识别（非写死）
  function loadProducts() {
    fetch('/api/products', { headers: { Accept: 'application/json' } })
      .then(function (r) { return r.json(); })
      .then(function (list) {
        productMap = {};
        (Array.isArray(list) ? list : []).forEach(function (p) {
          if (p && p.instanceCode) { productMap[p.instanceCode] = p; }
        });
      })
      .catch(function () { productMap = {}; });
  }

  function escapeHtml(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // 极简 Markdown→HTML（先转义再套白名单标签，安全）：**加粗**、`代码`、- 列表、换行
  function renderRich(text) {
    var esc = escapeHtml(String(text == null ? '' : text));
    esc = esc.replace(/\*\*([^*\n]+)\*\*/g, '<strong>$1</strong>')
             .replace(/`([^`\n]+)`/g, '<code class="aig-code">$1</code>');
    return esc.split('\n').map(function (ln) {
      if (/^\s*[-*]\s+/.test(ln)) {
        return '<div class="aig-li"><span class="aig-dot">•</span><span>' + ln.replace(/^\s*[-*]\s+/, '') + '</span></div>';
      }
      return ln.trim() === '' ? '' : '<div class="aig-row">' + ln + '</div>';
    }).join('');
  }

  // ============== 样式（独立注入，不依赖 Tailwind） ==============
  var css = ''
    + '.aig-ball{position:fixed;right:22px;bottom:100px;width:56px;height:56px;border-radius:50%;z-index:9990;cursor:pointer;'
    + 'background:linear-gradient(135deg,#0052d9,#7b5cf0);box-shadow:0 8px 24px -6px rgba(0,82,217,.55);display:flex;align-items:center;justify-content:center;'
    + 'color:#fff;font-size:22px;transition:transform .2s;animation:aigPulse 2.6s infinite}'
    + '.aig-ball:hover{transform:scale(1.08)}'
    + '.aig-ball .aig-tag{position:absolute;top:-4px;right:-4px;background:#ff6a00;color:#fff;font-size:10px;line-height:1;padding:3px 5px;border-radius:8px;font-weight:700}'
    + '@keyframes aigPulse{0%{box-shadow:0 8px 24px -6px rgba(0,82,217,.55),0 0 0 0 rgba(0,82,217,.30)}'
    + '70%{box-shadow:0 8px 24px -6px rgba(0,82,217,.55),0 0 0 14px rgba(0,82,217,0)}100%{box-shadow:0 8px 24px -6px rgba(0,82,217,.55),0 0 0 0 rgba(0,82,217,0)}}'
    + '.aig-panel{position:fixed;right:22px;bottom:170px;width:min(384px,calc(100vw - 32px));height:min(560px,calc(100vh - 200px));'
    + 'background:#fff;border-radius:16px;box-shadow:0 24px 64px -16px rgba(15,23,42,.35);z-index:9991;display:none;flex-direction:column;overflow:hidden;'
    + 'border:1px solid #e5e7eb;font-size:14px}'
    + '.aig-panel.aig-open{display:flex}'
    + '.aig-head{background:linear-gradient(135deg,#0052d9,#7b5cf0);color:#fff;padding:14px 16px;display:flex;align-items:center;justify-content:space-between}'
    + '.aig-head-title{font-weight:700;display:flex;align-items:center;gap:8px}'
    + '.aig-head-sub{font-size:11px;opacity:.85;margin-top:2px;font-weight:400}'
    + '.aig-head button{background:rgba(255,255,255,.18);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;margin-left:6px}'
    + '.aig-head button:hover{background:rgba(255,255,255,.3)}'
    + '.aig-body{flex:1;overflow-y:auto;padding:14px;background:#f6f8fb;display:flex;flex-direction:column;gap:10px}'
    + '.aig-msg{max-width:84%;padding:10px 12px;border-radius:12px;line-height:1.6;white-space:pre-wrap;word-break:break-word}'
    + '.aig-msg-user{align-self:flex-end;background:#0052d9;color:#fff;border-bottom-right-radius:4px}'
    + '.aig-msg-ai{align-self:flex-start;background:#fff;color:#1f2937;border:1px solid #e5e7eb;border-bottom-left-radius:4px}'
    + '.aig-msg-ai.aig-loading{color:#9ca3af}'
    + '.aig-act{align-self:flex-start;max-width:84%}'
    + '.aig-act-btn{display:inline-flex;align-items:center;gap:8px;background:linear-gradient(135deg,#0052d9,#7b5cf0);color:#fff;border:none;'
    + 'padding:10px 16px;border-radius:10px;font-size:13px;font-weight:600;cursor:pointer;box-shadow:0 6px 16px -6px rgba(0,82,217,.5)}'
    + '.aig-act-btn:hover{opacity:.92}.aig-act-btn:disabled{opacity:.55;cursor:not-allowed}'
    + '.aig-act-sum{font-size:12px;color:#6b7280;margin-top:6px}'
    + '.aig-foot{padding:10px;background:#fff;border-top:1px solid #f0f0f0;display:flex;gap:8px}'
    + '.aig-input{flex:1;border:1px solid #d1d5db;border-radius:10px;padding:9px 12px;font-size:14px;outline:none;resize:none;max-height:88px;font-family:inherit}'
    + '.aig-input:focus{border-color:#0052d9}'
    + '.aig-send{background:#0052d9;color:#fff;border:none;border-radius:10px;width:42px;cursor:pointer;flex-shrink:0}'
    + '.aig-send:disabled{opacity:.5;cursor:not-allowed}'
    + '.aig-hints{display:flex;flex-wrap:wrap;gap:6px;padding:0 14px 10px;background:#f6f8fb}'
    + '.aig-hint{font-size:12px;color:#0052d9;background:#eaf1ff;border:1px solid #d4e3ff;border-radius:999px;padding:4px 10px;cursor:pointer}'
    + '.aig-hint:hover{background:#dce9ff}'
    + '.aig-cursor{position:fixed;left:0;top:0;width:44px;height:44px;z-index:99999;pointer-events:none;display:none;'
    + 'transform:translate(-50%,-50%);transition:left .65s cubic-bezier(.22,.8,.36,1),top .65s cubic-bezier(.22,.8,.36,1)}'
    + '.aig-cursor .aig-cur-bg{position:absolute;inset:0;border-radius:50%;background:rgba(0,82,217,.16);border:1.5px solid rgba(0,82,217,.5);transition:transform .15s}'
    + '.aig-cursor .aig-cur-pt{position:absolute;left:50%;top:50%;transform:translate(-40%,-40%);color:#0052d9;font-size:17px;text-shadow:0 1px 2px rgba(255,255,255,.9)}'
    + '.aig-cursor.aig-press .aig-cur-bg{transform:scale(.72);background:rgba(0,82,217,.32)}'
    + '.aig-ripple{position:fixed;width:10px;height:10px;border-radius:50%;border:2px solid #0052d9;z-index:99998;pointer-events:none;'
    + 'transform:translate(-50%,-50%);animation:aigRip .55s ease-out forwards}'
    + '@keyframes aigRip{from{opacity:.85;width:10px;height:10px}to{opacity:0;width:64px;height:64px}}'
    + '.aig-stepbar{position:fixed;left:50%;top:14px;transform:translateX(-50%);z-index:9992;background:#111827;color:#fff;'
    + 'border-radius:999px;padding:9px 16px;font-size:13px;display:none;align-items:center;gap:12px;box-shadow:0 10px 30px -8px rgba(0,0,0,.4);max-width:calc(100vw - 32px)}'
    + '.aig-stepbar .aig-step-text{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}'
    + '.aig-stepbar button{background:#ef4444;border:none;color:#fff;border-radius:999px;padding:4px 12px;font-size:12px;cursor:pointer;flex-shrink:0}'
    + '.aig-msg-ai .aig-li{display:flex;gap:6px;margin:2px 0}'
    + '.aig-msg-ai .aig-dot{color:#0052d9;flex-shrink:0}'
    + '.aig-msg-ai .aig-code{background:#eef2ff;color:#3730a3;padding:1px 5px;border-radius:4px;font-size:12px}'
    + '.aig-msg-ai strong{color:#0f172a;font-weight:700}'
    + '.aig-msg-ai .aig-row{margin:1px 0}'
    + '.aig-panel.aig-left{right:auto;left:22px}'
    + '@media (max-width:480px){.aig-panel{right:16px;bottom:160px}.aig-ball{right:16px;bottom:92px}.aig-panel.aig-left{left:16px}}';

  // ============== 小工具 ==============
  function load(key) {
    try { return JSON.parse(sessionStorage.getItem(key) || 'null'); } catch (e) { return null; }
  }
  function save(key, val) {
    try {
      if (val == null) { sessionStorage.removeItem(key); } else { sessionStorage.setItem(key, JSON.stringify(val)); }
    } catch (e) { /* 隐私模式等场景忽略 */ }
  }
  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) { n.className = cls; }
    if (text != null) { n.textContent = text; }
    return n;
  }
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

  function pageKey() {
    var p = (location.pathname.split('/').pop() || 'index.jsp').toLowerCase();
    if (p === '' || p === 'index.jsp') { return 'home'; }
    if (p === 'products.jsp') { return 'products'; }
    if (p === 'purchase.jsp') { return 'purchase'; }
    if (p === 'auth.jsp') { return 'auth'; }
    return p.replace('.jsp', '');
  }

  function visible(node) {
    if (!node) { return false; }
    var r = node.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  }

  function waitFor(sel, timeout) {
    return new Promise(function (resolve) {
      var t0 = Date.now();
      (function poll() {
        var node = document.querySelector(sel);
        if (node && visible(node)) { resolve(node); return; }
        if (Date.now() - t0 > timeout) { resolve(null); return; }
        setTimeout(poll, 250);
      })();
    });
  }

  // ============== UI 构建 ==============
  var panel, body, input, sendBtn, ball, stepbar, stepText, cursorEl;

  function buildUI() {
    var style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);

    ball = el('div', 'aig-ball');
    ball.innerHTML = '<i class="fa-solid fa-robot"></i><span class="aig-tag">AI</span>';
    ball.title = 'AI 导购助手';
    ball.addEventListener('click', function () { togglePanel(!chat.open); });
    document.body.appendChild(ball);

    panel = el('div', 'aig-panel');
    var head = el('div', 'aig-head');
    var ht = el('div', 'aig-head-title');
    ht.innerHTML = '<i class="fa-solid fa-robot"></i><span>AI 导购助手<div class="aig-head-sub">帮您挑选并自动下单云服务器</div></span>';
    var hb = el('div');
    var clearBtn = el('button', null);
    clearBtn.innerHTML = '<i class="fa-solid fa-broom"></i>';
    clearBtn.title = '清空对话';
    clearBtn.addEventListener('click', function () {
      chat.messages = [];
      save(CHAT_KEY, chat);
      renderMessages();
    });
    var closeBtn = el('button', null);
    closeBtn.innerHTML = '<i class="fa-solid fa-xmark"></i>';
    closeBtn.title = '收起';
    closeBtn.addEventListener('click', function () { togglePanel(false); });
    hb.appendChild(clearBtn);
    hb.appendChild(closeBtn);
    head.appendChild(ht);
    head.appendChild(hb);

    body = el('div', 'aig-body');

    // 第 3 个为「问题类」快捷提示，每次加载从问题库随机抽一条（展示 AI 问题解决能力）
    var hintList = [
      '帮我选购一台广东的按量计费低配服务器',
      '推荐一台做深度学习的 GPU 服务器',
      PROBLEM_HINTS[Math.floor(Math.random() * PROBLEM_HINTS.length)]
    ];
    var hints = el('div', 'aig-hints');
    hintList.forEach(function (q) {
      var h = el('span', 'aig-hint', q);
      h.addEventListener('click', function () { input.value = q; send(); });
      hints.appendChild(h);
    });

    var foot = el('div', 'aig-foot');
    input = el('textarea', 'aig-input');
    input.rows = 1;
    input.placeholder = '例如：帮我选购一台广东的按量计费低配服务器';
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
    });
    sendBtn = el('button', 'aig-send');
    sendBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i>';
    sendBtn.addEventListener('click', send);
    foot.appendChild(input);
    foot.appendChild(sendBtn);

    panel.appendChild(head);
    panel.appendChild(body);
    panel.appendChild(hints);
    panel.appendChild(foot);
    document.body.appendChild(panel);

    stepbar = el('div', 'aig-stepbar');
    stepText = el('span', 'aig-step-text');
    var stopBtn = el('button', null, '停止');
    stopBtn.addEventListener('click', function () { cancelPlan('已手动停止自动操作。'); });
    stepbar.appendChild(stepText);
    stepbar.appendChild(stopBtn);
    document.body.appendChild(stepbar);

    cursorEl = el('div', 'aig-cursor');
    cursorEl.innerHTML = '<div class="aig-cur-bg"></div><i class="fa-solid fa-arrow-pointer aig-cur-pt"></i>';
    document.body.appendChild(cursorEl);

    if (chat.open) { panel.classList.add('aig-open'); }
    renderMessages();
  }

  function togglePanel(open) {
    chat.open = open;
    save(CHAT_KEY, chat);
    panel.classList.toggle('aig-open', open);
    if (open) { body.scrollTop = body.scrollHeight; }
  }

  function renderMessages() {
    body.innerHTML = '';
    if (!chat.messages.length) {
      var welcome = el('div', 'aig-msg aig-msg-ai',
        '您好，我是 AJOU 的 AI 导购助手 🤖\n告诉我您的用途、预算或地域，我来帮您挑选合适的云服务器，还可以自动帮您完成选购操作。');
      body.appendChild(welcome);
    }
    chat.messages.forEach(function (m, i) {
      var msgEl = el('div', 'aig-msg ' + (m.role === 'user' ? 'aig-msg-user' : 'aig-msg-ai'));
      if (m.role === 'user') {
        msgEl.textContent = m.content;
      } else {
        msgEl.innerHTML = renderRich(m.content); // 助手消息渲染加粗/列表等 HTML
      }
      body.appendChild(msgEl);
      if (m.role === 'assistant' && m.action && m.action.type === 'purchase') {
        body.appendChild(buildActionCard(m.action, i));
      }
      if (m.role === 'assistant' && m.link && m.link.slug) {
        body.appendChild(buildLinkCard(m.link));
      }
    });
    body.scrollTop = body.scrollHeight;
  }

  function buildActionCard(action, idx) {
    var wrap = el('div', 'aig-act');
    var btn = el('button', 'aig-act-btn');
    btn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles"></i> 让 AI 自动帮我下单';
    btn.addEventListener('click', function () {
      btn.disabled = true;
      // 保持对话窗打开（跨页也一直开着，内容一致）
      startPlan(action);
    });
    wrap.appendChild(btn);
    if (action.summary) {
      wrap.appendChild(el('div', 'aig-act-sum', '配置：' + action.summary));
    }
    return wrap;
  }

  function buildLinkCard(link) {
    var wrap = el('div', 'aig-act');
    var isQuestion = link.type === 'question';
    var url = isQuestion
      ? 'community-question-detail.jsp?question=' + encodeURIComponent(link.slug)
      : 'product-dynamics-detail.jsp?id=' + encodeURIComponent(link.slug);
    var btn = el('a', 'aig-act-btn');
    btn.href = url;
    btn.innerHTML = '<i class="fa-solid fa-arrow-up-right-from-square"></i>';
    btn.appendChild(document.createTextNode(
      (isQuestion ? '查看官方回复' : '查看解决方案') + (link.title ? '：' + link.title : '')));
    wrap.appendChild(btn);
    return wrap;
  }

  function pushMessage(role, content, action, link) {
    chat.messages.push({ role: role, content: content, action: action || null, link: link || null });
    if (chat.messages.length > 40) { chat.messages = chat.messages.slice(-40); }
    save(CHAT_KEY, chat);
    renderMessages();
  }

  // ============== 对话 ==============
  function send() {
    var text = (input.value || '').trim();
    if (!text || sending) { return; }
    input.value = '';
    pushMessage('user', text);
    sending = true;
    sendBtn.disabled = true;

    var loading = el('div', 'aig-msg aig-msg-ai aig-loading', 'AI 正在思考…');
    body.appendChild(loading);
    body.scrollTop = body.scrollHeight;

    var history = chat.messages.map(function (m) { return { role: m.role, content: m.content }; });

    fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: history })
    }).then(function (r) { return r.json(); }).then(function (res) {
      sending = false;
      sendBtn.disabled = false;
      if (!res || !res.success) {
        pushMessage('assistant', (res && res.message) || 'AI 服务暂不可用，请稍后再试。');
        return;
      }
      pushMessage('assistant', res.reply || '（无回复）', res.action || null, res.link || null);
    }).catch(function () {
      sending = false;
      sendBtn.disabled = false;
      pushMessage('assistant', '网络异常，AI 服务连接失败，请稍后再试。');
    });
  }

  // ============== 假鼠标 ==============
  function showCursor(x, y) {
    cursorEl.style.display = 'block';
    cursorEl.style.left = (x || window.innerWidth - 60) + 'px';
    cursorEl.style.top = (y || window.innerHeight - 140) + 'px';
  }
  function hideCursor() { cursorEl.style.display = 'none'; }

  function moveCursor(x, y) {
    return new Promise(function (resolve) {
      var cx = parseFloat(cursorEl.style.left) || 0;
      var cy = parseFloat(cursorEl.style.top) || 0;
      var dist = Math.hypot(x - cx, y - cy);
      var dur = Math.max(0.45, Math.min(1.0, dist / 900));
      cursorEl.style.transition = 'left ' + dur + 's cubic-bezier(.22,.8,.36,1), top ' + dur + 's cubic-bezier(.22,.8,.36,1)';
      cursorEl.style.left = x + 'px';
      cursorEl.style.top = y + 'px';
      setTimeout(resolve, dur * 1000 + 80);
    });
  }

  function clickFx(x, y) {
    return new Promise(function (resolve) {
      cursorEl.classList.add('aig-press');
      var rip = el('div', 'aig-ripple');
      rip.style.left = x + 'px';
      rip.style.top = y + 'px';
      document.body.appendChild(rip);
      setTimeout(function () {
        cursorEl.classList.remove('aig-press');
        if (rip.parentNode) { rip.parentNode.removeChild(rip); }
        resolve();
      }, 320);
    });
  }

  // ============== 自动选购计划 ==============
  function loadPlan() { return load(PLAN_KEY); }
  function savePlan(p) { save(PLAN_KEY, p); }

  var OPTION_DEFAULTS = { os: 'ubuntu', billing: 'monthly', duration: 1 };
  // region/os/billing/duration 对应购买页固定选项；instance 走实时 productMap，不写死
  var VALID = {
    region: ['beijing', 'shanghai', 'guangzhou', 'singapore'],
    os: ['ubuntu', 'centos', 'windows'],
    billing: ['monthly', 'hourly'],
    duration: [1, 3, 6, 12]
  };

  function pick(value, allowed, fallback) {
    return allowed.indexOf(value) >= 0 ? value : fallback;
  }

  // 用实时在售规格校验：AI 推荐的规格存在就用它，否则退回第一个在售规格
  function resolveInstance(code) {
    code = String(code || '').trim();
    if (productMap && Object.keys(productMap).length) {
      if (productMap[code]) { return code; }
      var keys = Object.keys(productMap);
      return keys.length ? keys[0] : (code || '2c4g');
    }
    return code || '2c4g'; // 列表未就绪时信任后端目录约束
  }

  function instanceIsGpu(code) {
    if (productMap && productMap[code]) { return productMap[code].category === 'gpu'; }
    return code.indexOf('gpu') === 0;
  }

  function buildSteps(action) {
    var instance = resolveInstance(action.instance);
    var region = pick(String(action.region || ''), VALID.region, 'beijing');
    var os = pick(String(action.os || ''), VALID.os, OPTION_DEFAULTS.os);
    var billing = pick(String(action.billing || ''), VALID.billing, OPTION_DEFAULTS.billing);
    var duration = pick(Number(action.duration || 1), VALID.duration, OPTION_DEFAULTS.duration);

    var steps = [];
    var page = pageKey();
    if (page !== 'purchase') {
      if (page !== 'products') {
        steps.push({ page: 'any', sel: '.site-nav-link[data-nav-key="products"]', label: '前往「产品购买」页', nav: true });
      }
      steps.push({ page: 'products', sel: '#product-sections a[href*="instance=' + instance + '"]', label: '选择产品并进入配置', nav: true });
    }
    steps.push({ page: 'purchase', sel: '[data-group="billing"][data-value="' + billing + '"]', label: '选择计费模式' });
    steps.push({ page: 'purchase', sel: '[data-group="region"][data-value="' + region + '"]', label: '选择地域' });
    steps.push({ page: 'purchase', sel: '[data-instance-tab="' + (instanceIsGpu(instance) ? 'gpu' : 'cpu') + '"]', label: '切换实例类型' });
    steps.push({ page: 'purchase', sel: '[data-group="instance"][data-value="' + instance + '"]', label: '选择实例规格' });
    steps.push({ page: 'purchase', sel: '[data-group="os"][data-value="' + os + '"]', label: '选择操作系统' });
    steps.push({ page: 'purchase', sel: '[data-group="diskType"][data-value="ssd"]', label: '选择系统盘' });
    if (billing === 'monthly') {
      steps.push({ page: 'purchase', sel: '[data-group="duration"][data-value="' + duration + '"]', label: '选择购买时长' });
    }
    steps.push({ page: 'purchase', sel: '#showBuyModal', label: '点击立即购买，打开支付', final: true });
    return steps;
  }

  function startPlan(action) {
    savePlan({ steps: buildSteps(action), idx: 0 });
    runPlan();
  }

  function cancelPlan(message) {
    savePlan(null);
    stepbar.style.display = 'none';
    hideCursor();
    if (message) { pushMessage('assistant', message); }
  }

  function finishPlan() {
    savePlan(null);
    stepText.textContent = '✅ 已打开支付弹窗，请完成真实支付';
    setTimeout(function () {
      stepbar.style.display = 'none';
      hideCursor();
    }, 6000);
    pushMessage('assistant', '✅ 已为您选好配置并点击「立即购买」，支付弹窗已打开。请扫码完成真实支付即可，本次自动操作到此结束～');
  }

  function setStep(text) {
    stepbar.style.display = 'flex';
    stepText.textContent = '🤖 AI 自动操作中：' + text;
  }

  async function runPlan() {
    var plan = loadPlan();
    if (!plan || !plan.steps || plan.idx >= plan.steps.length) { return; }

    if (pageKey() === 'auth') {
      setStep('请先登录，登录后我会继续自动选购');
      return; // 登录回跳后由新页面恢复执行
    }

    // 自动操作期间保持对话窗打开（固定右下角，不随翻页左右移动）
    togglePanel(true);
    showCursor();
    while (true) {
      plan = loadPlan();
      if (!plan) { break; } // 已被取消
      if (plan.idx >= plan.steps.length) { finishPlan(); break; }

      var step = plan.steps[plan.idx];
      var page = pageKey();
      if (step.page !== 'any' && step.page !== page) {
        cancelPlan('当前页面与选购流程不一致，自动操作已停止。您可以重新发起。');
        break;
      }

      setStep(step.label + '（' + (plan.idx + 1) + '/' + plan.steps.length + '）');
      var target = await waitFor(step.sel, 12000);
      if (!target) {
        cancelPlan('没有找到要操作的页面元素，自动操作已停止。');
        break;
      }

      target.scrollIntoView({ behavior: 'smooth', block: 'center' });
      await sleep(480);
      var rect = target.getBoundingClientRect();
      var x = rect.left + rect.width / 2;
      var y = rect.top + rect.height / 2;
      await moveCursor(x, y);
      await clickFx(x, y);

      // 先推进进度再点击：点击若触发跳转，新页面可从下一步继续
      plan.idx += 1;
      savePlan(plan);
      target.click();

      if (step.nav) {
        // 导航步骤：本页即将卸载，停止循环，由新页面恢复执行计划
        setStep('正在前往下一个页面…');
        break;
      }
      if (step.final) {
        // 点「立即购买」后等支付弹窗出现，弹出即结束（弹窗不会自动支付）
        await waitFor('#buy-modal', 5000);
        await sleep(400);
        finishPlan();
        break;
      }
      await sleep(620);
    }
  }

  // ============== 启动 ==============
  function init() {
    if (!document.body) { return; }
    loadProducts(); // 实时拉取在售规格
    buildUI();
    var plan = loadPlan();
    if (plan && plan.steps && plan.idx < plan.steps.length) {
      // 等 layout.js 异步渲染头部导航后再续跑
      setTimeout(runPlan, 900);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
