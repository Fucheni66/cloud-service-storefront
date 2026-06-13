<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="${from eq 'instances' ? 'instances' : 'orders'}"/>
<c:set var="backUrl" value="${from eq 'instances' ? '/admin/instances' : '/admin/orders'}"/>
<c:set var="pageTitle" value="${from eq 'instances' ? '云实例详情' : '订单详情'}"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>${pageTitle} · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>
    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>
        <main class="flex-1 p-6">
            <div class="text-sm text-gray-500 mb-4">
                <a href="${pageContext.request.contextPath}${backUrl}" class="hover:text-primary">${from eq 'instances' ? '云实例管理' : '订单管理'}</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <div class="flex items-center justify-between pb-5 border-b border-gray-100">
                    <div>
                        <div class="text-xl font-bold text-gray-900">${order.instanceName}</div>
                        <div class="text-sm text-gray-500 font-mono">${order.orderNo}</div>
                    </div>
                    <c:choose>
                        <c:when test="${order.status eq 'running'}"><span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2.5 py-1">运行中</span></c:when>
                        <c:when test="${order.status eq 'pending'}"><span class="text-xs bg-orange-50 text-orange-500 border border-orange-200 rounded-full px-2.5 py-1">待支付</span></c:when>
                        <c:when test="${order.status eq 'expired'}"><span class="text-xs bg-red-50 text-red-500 border border-red-200 rounded-full px-2.5 py-1">已到期</span></c:when>
                        <c:otherwise><span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2.5 py-1">${order.statusLabel}</span></c:otherwise>
                    </c:choose>
                </div>

                <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 py-5 text-sm">
                    <div><dt class="text-gray-500">下单用户</dt><dd class="text-gray-900 mt-0.5">${order.userEmail}</dd></div>
                    <div><dt class="text-gray-500">金额</dt><dd class="text-gray-900 mt-0.5 font-medium">¥${order.amount}（${order.billingLabel}）</dd></div>
                    <div><dt class="text-gray-500">规格</dt><dd class="text-gray-900 mt-0.5">${order.instanceCode}</dd></div>
                    <div><dt class="text-gray-500">地域</dt><dd class="text-gray-900 mt-0.5">${order.regionLabel}</dd></div>
                    <div><dt class="text-gray-500">操作系统</dt><dd class="text-gray-900 mt-0.5">${order.os}</dd></div>
                    <div><dt class="text-gray-500">磁盘</dt><dd class="text-gray-900 mt-0.5">${order.disk}</dd></div>
                    <div><dt class="text-gray-500">公网 IP</dt><dd class="text-gray-900 mt-0.5 font-mono">${empty order.publicIp ? '—' : order.publicIp}</dd></div>
                    <div><dt class="text-gray-500">下单时间</dt><dd class="text-gray-900 mt-0.5"><fmt:formatDate value="${order.createdAt}" pattern="yyyy-MM-dd HH:mm"/></dd></div>
                    <div><dt class="text-gray-500">支付时间</dt><dd class="text-gray-900 mt-0.5"><c:choose><c:when test="${empty order.paidAt}">—</c:when><c:otherwise><fmt:formatDate value="${order.paidAt}" pattern="yyyy-MM-dd HH:mm"/></c:otherwise></c:choose></dd></div>
                    <div><dt class="text-gray-500">到期时间</dt><dd class="mt-0.5 ${order.expiringSoon ? 'text-red-500 font-medium' : 'text-gray-900'}"><c:choose><c:when test="${empty order.expireAt}">—</c:when><c:otherwise><fmt:formatDate value="${order.expireAt}" pattern="yyyy-MM-dd"/><c:if test="${order.expiringSoon}"> · 即将到期</c:if></c:otherwise></c:choose></dd></div>
                </dl>

                <div class="flex items-center gap-3 pt-4 border-t border-gray-100">
                    <c:if test="${order.pending}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/orders">
                            <input type="hidden" name="action" value="pay">
                            <input type="hidden" name="id" value="${order.id}">
                            <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">标记开通</button>
                        </form>
                    </c:if>
                    <c:if test="${order.status eq 'running' or order.status eq 'expired'}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/instances">
                            <input type="hidden" name="action" value="renew">
                            <input type="hidden" name="id" value="${order.id}">
                            <button type="submit" class="border border-gray-300 bg-white text-gray-700 rounded px-5 py-2.5 text-sm hover:text-primary hover:border-primary transition">续费 1 个月</button>
                        </form>
                    </c:if>
                    <c:if test="${order.status eq 'running'}">
                        <form method="post" action="${pageContext.request.contextPath}/admin/instances"
                              onsubmit="return confirm('确定释放该实例？');">
                            <input type="hidden" name="action" value="release">
                            <input type="hidden" name="id" value="${order.id}">
                            <button type="submit" class="border border-gray-300 bg-white text-gray-700 rounded px-5 py-2.5 text-sm hover:text-red-500 hover:border-red-300 transition">释放实例</button>
                        </form>
                    </c:if>
                    <form method="post" action="${pageContext.request.contextPath}/admin/orders"
                          onsubmit="return confirm('确定删除该订单？');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="${order.id}">
                        <button type="submit" class="border border-red-200 bg-white text-red-500 rounded px-5 py-2.5 text-sm hover:bg-red-50 transition">删除</button>
                    </form>
                    <a href="${pageContext.request.contextPath}${backUrl}" class="ml-auto text-sm text-gray-500 hover:text-primary">返回列表</a>
                </div>
            </div>
        </main>
    </div>
</div>
</body>
</html>
