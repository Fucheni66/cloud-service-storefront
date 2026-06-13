<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="instances"/>
<c:set var="pageTitle" value="云实例管理"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>云实例管理 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>
    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>
        <main class="flex-1 p-6">
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-900">云实例管理</h2>
                <p class="text-sm text-gray-500 mt-1">共 ${instances.size()} 个已开通实例 · <span class="text-red-500">红色到期时间</span>表示 7 天内即将到期，需提醒续费</p>
            </div>

            <%-- 筛选 + 搜索：按型号 / 状态 / 用户邮箱 --%>
            <form method="get" action="${pageContext.request.contextPath}/admin/instances"
                  class="bg-white rounded-xl border border-gray-200 shadow-sm p-4 mb-4 flex flex-wrap items-center gap-3">
                <select name="instanceCode" class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary">
                    <option value="" ${empty instanceCode ? 'selected' : ''}>全部型号</option>
                    <c:forEach var="s" items="${specs}">
                        <option value="${s.instanceCode}" ${instanceCode eq s.instanceCode ? 'selected' : ''}>${s.title}（${s.instanceCode}）</option>
                    </c:forEach>
                </select>
                <select name="status" class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary">
                    <option value="" ${empty status ? 'selected' : ''}>全部状态</option>
                    <option value="running" ${status eq 'running' ? 'selected' : ''}>运行中</option>
                    <option value="expired" ${status eq 'expired' ? 'selected' : ''}>已到期</option>
                </select>
                <input type="text" name="q" value="${q}" placeholder="搜索用户邮箱 / 实例名 / 订单号"
                       class="border border-gray-300 rounded px-3 py-2 text-sm flex-1 min-w-[220px] focus:outline-none focus:border-primary">
                <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-5 py-2 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-magnifying-glass mr-1"></i> 搜索
                </button>
                <a href="${pageContext.request.contextPath}/admin/instances" class="text-sm text-gray-500 hover:text-primary">重置</a>
            </form>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">实例</th>
                            <th class="px-4 py-3 font-medium">配置</th>
                            <th class="px-4 py-3 font-medium">地域</th>
                            <th class="px-4 py-3 font-medium">公网 IP</th>
                            <th class="px-4 py-3 font-medium">用户</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium">到期时间</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="o" items="${instances}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3">
                                    <div class="text-gray-900 font-medium">${o.instanceName}</div>
                                    <div class="text-xs text-gray-400 font-mono">${o.orderNo}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${o.instanceCode}<div class="text-xs text-gray-400">${o.os} · ${o.disk}</div></td>
                                <td class="px-4 py-3 text-gray-600">${o.regionLabel}</td>
                                <td class="px-4 py-3 font-mono text-gray-600">${empty o.publicIp ? '—' : o.publicIp}</td>
                                <td class="px-4 py-3 text-gray-500">${o.userEmail}</td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${o.status eq 'running'}"><span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">运行中</span></c:when>
                                        <c:otherwise><span class="text-xs bg-red-50 text-red-500 border border-red-200 rounded-full px-2 py-0.5">已到期</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3 ${o.expiringSoon ? 'text-red-500 font-medium' : 'text-gray-500'}">
                                    <c:choose><c:when test="${empty o.expireAt}">—</c:when><c:otherwise><fmt:formatDate value="${o.expireAt}" pattern="yyyy-MM-dd"/></c:otherwise></c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/instances?action=detail&id=${o.id}" class="text-primary hover:underline">详情</a>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/instances" class="inline">
                                            <input type="hidden" name="action" value="renew">
                                            <input type="hidden" name="id" value="${o.id}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">续费</button>
                                        </form>
                                        <c:if test="${o.status eq 'running'}">
                                            <form method="post" action="${pageContext.request.contextPath}/admin/instances" class="inline"
                                                  onsubmit="return confirm('确定释放实例 ${o.instanceName}？');">
                                                <input type="hidden" name="action" value="release">
                                                <input type="hidden" name="id" value="${o.id}">
                                                <button type="submit" class="text-red-500 hover:underline">释放</button>
                                            </form>
                                        </c:if>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty instances}">
                            <tr><td colspan="8" class="px-4 py-10 text-center text-gray-400">没有符合条件的云实例</td></tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>
</div>
</body>
</html>
