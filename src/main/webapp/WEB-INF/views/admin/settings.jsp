<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="active" value="settings"/>
<c:set var="pageTitle" value="系统设置"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="fragments/head.jspf" %>
    <title>系统设置 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="fragments/sidebar.jspf" %>
    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="fragments/topbar.jspf" %>
        <main class="flex-1 p-6">
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-900">系统设置</h2>
                <p class="text-sm text-gray-500 mt-1">第三方对接与站点参数配置 · 敏感项（密钥/私钥）不回显，留空表示保持原值</p>
            </div>

            <c:if test="${param.saved eq '1'}">
                <div class="mb-4 rounded bg-green-50 border border-green-200 text-green-600 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-circle-check"></i> 配置已保存
                </div>
            </c:if>
            <c:if test="${param.tested eq '1'}">
                <div class="mb-4 rounded bg-green-50 border border-green-200 text-green-600 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-paper-plane"></i> 测试邮件已发送，请到收件箱查收
                </div>
            </c:if>
            <c:if test="${not empty param.testError}">
                <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-circle-exclamation"></i> 测试邮件发送失败：${param.testError}
                </div>
            </c:if>

            <%-- 分组 tab --%>
            <div class="flex gap-1 mb-4 border-b border-gray-200">
                <c:forEach var="g" items="${['google','alipay','wechat','site','ai','smtp']}">
                    <c:set var="gLabel" value="${g eq 'google' ? 'Google 登录' : (g eq 'alipay' ? '支付宝当面付' : (g eq 'wechat' ? '微信 JSAPI' : (g eq 'site' ? '站点基础' : (g eq 'ai' ? 'AI 大模型' : 'SMTP 邮件'))))}"/>
                    <a href="${pageContext.request.contextPath}/admin/settings?group=${g}"
                       class="px-4 py-2.5 text-sm font-medium border-b-2 -mb-px ${group eq g ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-primary'}">
                        ${gLabel}
                    </a>
                </c:forEach>
            </div>

            <%-- 当前分组表单 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <form action="${pageContext.request.contextPath}/admin/settings" method="post" class="space-y-5">
                    <input type="hidden" name="group" value="${group}">
                    <c:forEach var="c" items="${configs}">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">
                                ${c.label}
                                <c:if test="${c.secret}"><span class="ml-1 text-[10px] text-orange-500 border border-orange-200 rounded px-1">敏感</span></c:if>
                            </label>
                            <c:choose>
                                <c:when test="${c.secret}">
                                    <%-- 敏感项：不回显原值，placeholder 显示状态 --%>
                                    <input type="password" name="${c.configKey}" autocomplete="new-password"
                                           class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                           placeholder="${c.configured ? '已配置（留空则不修改）' : '未配置'}">
                                </c:when>
                                <c:when test="${fn:contains(c.configKey, 'prompt')}">
                                    <%-- 多行文本（如附加系统提示词）：用 textarea 完整展示与编辑 --%>
                                    <textarea name="${c.configKey}" rows="8"
                                              class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm leading-6 focus:outline-none focus:border-primary"
                                              placeholder="选填，留空使用内置提示词">${c.configValue}</textarea>
                                </c:when>
                                <c:otherwise>
                                    <input type="text" name="${c.configKey}" value="${c.configValue}"
                                           class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                </c:otherwise>
                            </c:choose>
                            <p class="text-xs text-gray-400 mt-1 font-mono">${c.configKey}</p>
                        </div>
                    </c:forEach>

                    <div class="pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            保存配置
                        </button>
                    </div>
                </form>
            </div>

            <%-- SMTP 分组：发送测试邮件（请先保存配置；注意真实发信，勿频繁测试） --%>
            <c:if test="${group eq 'smtp'}">
                <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl mt-4">
                    <h3 class="text-base font-bold text-gray-900 mb-1">发送测试邮件</h3>
                    <p class="text-xs text-gray-400 mb-4">向指定邮箱发送一封测试邮件，验证 SMTP 是否配置正确。请先保存上方配置，且勿频繁测试以免邮箱被风控。</p>
                    <form action="${pageContext.request.contextPath}/admin/settings" method="post" class="flex flex-wrap items-center gap-3">
                        <input type="hidden" name="action" value="testMail">
                        <input type="hidden" name="group" value="smtp">
                        <input type="email" name="testTo" required placeholder="收件邮箱，如 admin@example.com"
                               class="border border-gray-300 rounded px-3 py-2.5 text-sm flex-1 min-w-[260px] focus:outline-none focus:border-primary">
                        <button type="submit"
                                class="border border-primary text-primary hover:bg-blue-50 rounded px-5 py-2.5 text-sm font-medium transition">
                            <i class="fa-solid fa-paper-plane mr-1"></i> 发送测试邮件
                        </button>
                    </form>
                </div>
            </c:if>
        </main>
    </div>
</div>
</body>
</html>
