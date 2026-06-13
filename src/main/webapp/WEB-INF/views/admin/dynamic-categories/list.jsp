<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="dynamic-categories"/>
<c:set var="pageTitle" value="动态分类"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>动态分类 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="text-sm text-gray-500 mb-4">
                <a href="${pageContext.request.contextPath}/admin/dynamics" class="hover:text-primary">产品动态</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">动态分类</span>
            </div>

            <c:if test="${not empty sessionScope.flashError}">
                <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                    <i class="fa-solid fa-circle-exclamation"></i> ${sessionScope.flashError}
                </div>
                <c:remove var="flashError" scope="session"/>
            </c:if>

            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">动态分类</h2>
                    <p class="text-sm text-gray-500 mt-1">共 ${categories.size()} 个 · 自定义产品动态的分类与配色，前台导航与发布选项随之更新</p>
                </div>
                <a href="${pageContext.request.contextPath}/admin/dynamic-categories?action=new"
                   class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-plus mr-2"></i> 新增分类
                </a>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div style="overflow-x:auto">
                <table class="w-full text-sm whitespace-nowrap" style="min-width:820px">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">排序</th>
                            <th class="px-4 py-3 font-medium">标识</th>
                            <th class="px-4 py-3 font-medium">名称 / 角标预览</th>
                            <th class="px-4 py-3 font-medium">文章数</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="cat" items="${categories}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3 text-gray-400">${cat.sortOrder}</td>
                                <td class="px-4 py-3"><span class="font-mono text-gray-900">${cat.code}</span></td>
                                <td class="px-4 py-3">
                                    <span class="inline-flex items-center text-xs font-medium px-2 py-1 rounded ${cat.badgeClass}">${cat.name}</span>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${cat.postCount}</td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${cat.active}">
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">启用</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">停用</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3" style="white-space:nowrap">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/dynamic-categories?action=edit&id=${cat.id}"
                                           class="text-primary hover:underline">编辑</a>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/dynamic-categories" class="inline">
                                            <input type="hidden" name="action" value="toggle">
                                            <input type="hidden" name="id" value="${cat.id}">
                                            <input type="hidden" name="active" value="${cat.active ? 0 : 1}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">${cat.active ? '停用' : '启用'}</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/dynamic-categories" class="inline"
                                              onsubmit="return confirm('确定删除分类「${cat.name}」？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${cat.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty categories}">
                            <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400">暂无分类</td></tr>
                        </c:if>
                    </tbody>
                </table>
                </div>
            </div>
        </main>
    </div>
</div>
</body>
</html>
