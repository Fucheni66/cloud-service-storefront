<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="dashboard"/>
<c:set var="pageTitle" value="仪表盘"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="fragments/head.jspf" %>
    <title>仪表盘 · AJOU 管理后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <%-- 数据库错误提示 --%>
            <c:if test="${not empty dbError}">
                <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-triangle-exclamation"></i> ${dbError}
                </div>
            </c:if>

            <%-- 欢迎语 --%>
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-900">欢迎回来，${sessionScope.admin.displayName}</h2>
                <p class="text-sm text-gray-500 mt-1">这里是 AJOU 云服务管理后台的数据概览。</p>
            </div>

            <%-- 云服务商核心 KPI（待接入 users / cloud_instances / 订单数据，雏形阶段占位）--%>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                <%-- 注册用户数（真实）--%>
                <a href="${pageContext.request.contextPath}/admin/users" class="block bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md transition">
                    <div class="flex items-center justify-between">
                        <p class="text-sm text-gray-500">注册用户数</p>
                        <i class="fa-solid fa-users text-primary"></i>
                    </div>
                    <p class="text-3xl font-bold text-gray-900 mt-2">${stats.userCount}</p>
                    <span class="inline-block mt-1 text-[11px] text-primary">查看用户 →</span>
                </a>
                <%-- 本月营收（真实）--%>
                <a href="${pageContext.request.contextPath}/admin/orders" class="block bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md transition">
                    <div class="flex items-center justify-between">
                        <p class="text-sm text-gray-500">本月营收</p>
                        <i class="fa-solid fa-coins text-primary"></i>
                    </div>
                    <p class="text-3xl font-bold text-gray-900 mt-2">¥${stats.monthlyRevenue}</p>
                    <span class="inline-block mt-1 text-[11px] text-primary">查看订单 →</span>
                </a>
                <%-- 运行中实例（真实）--%>
                <a href="${pageContext.request.contextPath}/admin/instances" class="block bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md transition">
                    <div class="flex items-center justify-between">
                        <p class="text-sm text-gray-500">运行中实例</p>
                        <i class="fa-solid fa-server text-primary"></i>
                    </div>
                    <p class="text-3xl font-bold text-gray-900 mt-2">${stats.runningInstances}</p>
                    <span class="inline-block mt-1 text-[11px] text-primary">查看实例 →</span>
                </a>
                <%-- 7 天内到期（真实，续费提醒）--%>
                <a href="${pageContext.request.contextPath}/admin/instances" class="block bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md transition">
                    <div class="flex items-center justify-between">
                        <p class="text-sm text-gray-500">7 天内到期</p>
                        <i class="fa-solid fa-clock ${stats.expiringSoon > 0 ? 'text-red-500' : 'text-primary'}"></i>
                    </div>
                    <p class="text-3xl font-bold mt-2 ${stats.expiringSoon > 0 ? 'text-red-500' : 'text-gray-900'}">${stats.expiringSoon}</p>
                    <span class="inline-block mt-1 text-[11px] text-primary">续费提醒 →</span>
                </a>
            </div>

            <%-- 最近注册管理员（真实数据）--%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-bold text-gray-900">最近注册的管理员</h3>
                    <span class="text-xs bg-primary/10 text-primary rounded-full px-2.5 py-1">共 ${stats.adminCount} 名管理员</span>
                </div>
                <c:choose>
                    <c:when test="${empty stats.recentAdmins}">
                        <p class="text-sm text-gray-400">暂无数据</p>
                    </c:when>
                    <c:otherwise>
                        <table class="w-full text-sm">
                            <thead>
                                <tr class="text-left text-gray-500 border-b border-gray-100">
                                    <th class="py-2 font-medium">ID</th>
                                    <th class="py-2 font-medium">用户名</th>
                                    <th class="py-2 font-medium">显示名</th>
                                    <th class="py-2 font-medium">角色</th>
                                    <th class="py-2 font-medium">注册时间</th>
                                    <th class="py-2 font-medium">最近登录</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="a" items="${stats.recentAdmins}">
                                    <tr class="border-b border-gray-50 text-gray-700">
                                        <td class="py-2.5">${a.id}</td>
                                        <td class="py-2.5 font-medium text-gray-900">${a.username}</td>
                                        <td class="py-2.5">${a.displayName}</td>
                                        <td class="py-2.5">
                                            <span class="text-xs border border-gray-200 rounded-full px-2 py-0.5 text-gray-600">${a.role}</span>
                                        </td>
                                        <td class="py-2.5 text-gray-500">
                                            <fmt:formatDate value="${a.createdAt}" pattern="yyyy-MM-dd HH:mm"/>
                                        </td>
                                        <td class="py-2.5 text-gray-500">
                                            <c:choose>
                                                <c:when test="${empty a.lastLoginAt}">—</c:when>
                                                <c:otherwise><fmt:formatDate value="${a.lastLoginAt}" pattern="yyyy-MM-dd HH:mm"/></c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </c:otherwise>
                </c:choose>
            </div>
        </main>
    </div>
</div>
</body>
</html>
