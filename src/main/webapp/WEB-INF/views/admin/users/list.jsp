<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="users"/>
<c:set var="pageTitle" value="用户管理"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>用户管理 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-900">用户管理</h2>
                <p class="text-sm text-gray-500 mt-1">共 ${users.size()} 个用户 · 用户由前台注册，后台可查看、搜索、启用/禁用</p>
            </div>

            <%-- 筛选 + 搜索 --%>
            <form method="get" action="${pageContext.request.contextPath}/admin/users"
                  class="bg-white rounded-xl border border-gray-200 shadow-sm p-4 mb-4 flex flex-wrap items-center gap-3">
                <select name="provider" class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary">
                    <option value="" ${empty provider ? 'selected' : ''}>全部来源</option>
                    <option value="email" ${provider eq 'email' ? 'selected' : ''}>邮箱注册</option>
                    <option value="google" ${provider eq 'google' ? 'selected' : ''}>Google 登录</option>
                </select>
                <input type="text" name="q" value="${q}" placeholder="搜索邮箱或昵称"
                       class="border border-gray-300 rounded px-3 py-2 text-sm flex-1 min-w-[200px] focus:outline-none focus:border-primary">
                <button type="submit" class="bg-primary hover:bg-primary-hover text-white rounded px-5 py-2 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-magnifying-glass mr-1"></i> 搜索
                </button>
                <a href="${pageContext.request.contextPath}/admin/users" class="text-sm text-gray-500 hover:text-primary">重置</a>
            </form>

            <%-- 列表 --%>
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">用户</th>
                            <th class="px-4 py-3 font-medium">来源</th>
                            <th class="px-4 py-3 font-medium">登录次数</th>
                            <th class="px-4 py-3 font-medium">注册时间</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="u" items="${users}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3">
                                    <div class="flex items-center">
                                        <c:choose>
                                            <c:when test="${not empty u.picture}">
                                                <img src="${u.picture}" alt="" class="w-8 h-8 rounded-full mr-3" referrerpolicy="no-referrer">
                                            </c:when>
                                            <c:otherwise>
                                                <span class="w-8 h-8 rounded-full bg-blue-50 text-primary flex items-center justify-center mr-3"><i class="fa-solid fa-user text-xs"></i></span>
                                            </c:otherwise>
                                        </c:choose>
                                        <div>
                                            <div class="font-medium text-gray-900">${empty u.displayName ? '(未命名)' : u.displayName}</div>
                                            <div class="text-xs text-gray-400">${u.email}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${u.google}">
                                            <span class="text-xs bg-red-50 text-red-500 rounded-full px-2 py-0.5"><i class="fa-brands fa-google mr-1"></i>Google</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-blue-50 text-primary rounded-full px-2 py-0.5"><i class="fa-solid fa-envelope mr-1"></i>邮箱</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${u.loginCount}</td>
                                <td class="px-4 py-3 text-gray-500"><fmt:formatDate value="${u.createdAt}" pattern="yyyy-MM-dd"/></td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${u.disabled}">
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已禁用</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">正常</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/users?action=detail&id=${u.id}" class="text-primary hover:underline">详情</a>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/users" class="inline">
                                            <input type="hidden" name="action" value="toggle">
                                            <input type="hidden" name="id" value="${u.id}">
                                            <input type="hidden" name="status" value="${u.disabled ? 'active' : 'disabled'}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">${u.disabled ? '启用' : '禁用'}</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/users" class="inline"
                                              onsubmit="return confirm('确定删除用户「${empty u.displayName ? u.email : u.displayName}」？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty users}">
                            <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400">没有符合条件的用户</td></tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>
</div>
</body>
</html>
