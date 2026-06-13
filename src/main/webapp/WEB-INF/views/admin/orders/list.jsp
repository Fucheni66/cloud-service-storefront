<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="orders"/>
<c:set var="pageTitle" value="订单管理"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>订单管理 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>
    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>
        <main class="flex-1 p-6">
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-900">订单管理</h2>
                <p class="text-sm text-gray-500 mt-1">共 ${orders.size()} 笔订单 · 云实例购买与开通记录</p>
            </div>

            <%-- 筛选 + 搜索 --%>
            <form method="get" action="${pageContext.request.contextPath}/admin/orders"
                  class="bg-white rounded-xl border border-gray-200 shadow-sm p-4 mb-4 flex flex-wrap items-center gap-3">
                <select name="status" class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary">
                    <option value="" ${empty status ? 'selected' : ''}>全部状态</option>
                    <option value="running"  ${status eq 'running'  ? 'selected' : ''}>运行中</option>
                    <option value="expired"  ${status eq 'expired'  ? 'selected' : ''}>已到期</option>
                    <option value="pending"  ${status eq 'pending'  ? 'selected' : ''}>待支付</option>
                    <option value="released" ${status eq 'released' ? 'selected' : ''}>已释放</option>
                </select>
                <input type="text" name="q" value="${q}" placeholder="搜索订单号或邮箱"
                       class="border border-gray-300 rounded px-3 py-2 text-sm flex-1 min-w-[200px] focus:outline-none focus:border-primary">
                <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-5 py-2 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-magnifying-glass mr-1"></i> 搜索
                </button>
                <a href="${pageContext.request.contextPath}/admin/orders" class="text-sm text-gray-500 hover:text-primary">重置</a>
            </form>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">订单号</th>
                            <th class="px-4 py-3 font-medium">用户</th>
                            <th class="px-4 py-3 font-medium">实例</th>
                            <th class="px-4 py-3 font-medium">金额</th>
                            <th class="px-4 py-3 font-medium">计费</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium">下单时间</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="o" items="${orders}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3 font-mono text-gray-900">${o.orderNo}</td>
                                <td class="px-4 py-3 text-gray-600">${o.userEmail}</td>
                                <td class="px-4 py-3">
                                    <div class="text-gray-900">${o.instanceName}</div>
                                    <div class="text-xs text-gray-400">${o.instanceCode} · ${o.regionLabel}</div>
                                </td>
                                <td class="px-4 py-3 font-medium text-gray-900">¥${o.amount}</td>
                                <td class="px-4 py-3 text-gray-600">${o.billingLabel}</td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${o.status eq 'running'}"><span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">运行中</span></c:when>
                                        <c:when test="${o.status eq 'pending'}"><span class="text-xs bg-orange-50 text-orange-500 border border-orange-200 rounded-full px-2 py-0.5">待支付</span></c:when>
                                        <c:when test="${o.status eq 'expired'}"><span class="text-xs bg-red-50 text-red-500 border border-red-200 rounded-full px-2 py-0.5">已到期</span></c:when>
                                        <c:otherwise><span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">${o.statusLabel}</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3 text-gray-500"><fmt:formatDate value="${o.createdAt}" pattern="yyyy-MM-dd"/></td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/orders?action=detail&id=${o.id}" class="text-primary hover:underline">详情</a>
                                        <c:if test="${o.pending}">
                                            <form method="post" action="${pageContext.request.contextPath}/admin/orders" class="inline">
                                                <input type="hidden" name="action" value="pay">
                                                <input type="hidden" name="id" value="${o.id}">
                                                <button type="submit" class="text-green-600 hover:underline">标记开通</button>
                                            </form>
                                        </c:if>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/orders" class="inline"
                                              onsubmit="return confirm('确定删除订单 ${o.orderNo}？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${o.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty orders}">
                            <tr><td colspan="8" class="px-4 py-10 text-center text-gray-400">没有符合条件的订单</td></tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>
</div>
</body>
</html>
