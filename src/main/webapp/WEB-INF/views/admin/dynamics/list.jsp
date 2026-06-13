<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="dynamics"/>
<c:set var="pageTitle" value="产品动态"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>产品动态 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">产品动态（CMS 发布）</h2>
                    <p class="text-sm text-gray-500 mt-1">共 ${total} 篇 · 分类与配色在「动态分类」中维护，精选教程为 tutorial 分类</p>
                </div>
                <div class="flex items-center gap-3">
                    <a href="${pageContext.request.contextPath}/admin/dynamic-categories"
                       class="inline-flex items-center bg-white border border-gray-300 text-gray-700 hover:text-primary hover:border-primary rounded px-4 py-2.5 text-sm font-medium transition">
                        <i class="fa-solid fa-tags mr-2"></i> 管理分类
                    </a>
                    <a href="${pageContext.request.contextPath}/admin/dynamics?action=new"
                       class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                        <i class="fa-solid fa-plus mr-2"></i> 发布动态
                    </a>
                </div>
            </div>

            <%-- 筛选：分类 + 关键词搜索 --%>
            <form method="get" action="${pageContext.request.contextPath}/admin/dynamics"
                  class="flex flex-col sm:flex-row sm:items-center gap-3 mb-4">
                <select name="category" class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary">
                    <option value="">全部分类</option>
                    <c:forEach var="cat" items="${categories}">
                        <option value="${cat.code}" ${categoryFilter eq cat.code ? 'selected' : ''}>${cat.name}</option>
                    </c:forEach>
                </select>
                <input type="text" name="q" value="${keyword}" placeholder="搜索标题 / URL 标识 / 摘要"
                       class="border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary sm:w-72">
                <div class="flex items-center gap-2">
                    <button type="submit" class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-4 py-2 text-sm font-medium transition">
                        <i class="fa-solid fa-magnifying-glass mr-2 text-xs"></i> 筛选
                    </button>
                    <c:if test="${not empty categoryFilter or not empty keyword}">
                        <a href="${pageContext.request.contextPath}/admin/dynamics" class="text-sm text-gray-500 hover:text-primary">重置</a>
                    </c:if>
                </div>
            </form>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div style="overflow-x:auto">
                <table class="w-full text-sm whitespace-nowrap" style="min-width:1080px">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">排序</th>
                            <th class="px-4 py-3 font-medium">URL 标识</th>
                            <th class="px-4 py-3 font-medium">分类</th>
                            <th class="px-4 py-3 font-medium">标题</th>
                            <th class="px-4 py-3 font-medium">发布日期</th>
                            <th class="px-4 py-3 font-medium">浏览</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="p" items="${posts}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3 text-gray-400">${p.sortOrder}</td>
                                <td class="px-4 py-3"><span class="font-mono text-gray-900">${p.slug}</span></td>
                                <td class="px-4 py-3">
                                    <span class="inline-flex items-center text-xs font-medium px-2 py-1 rounded ${p.badgeClass}">${p.categoryLabel}</span>
                                </td>
                                <td class="px-4 py-3" style="white-space:normal;min-width:260px;max-width:420px">
                                    <div class="font-medium text-gray-900">${p.title}</div>
                                    <div class="text-xs text-gray-400">${p.summary}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${p.publishedAt}</td>
                                <td class="px-4 py-3 text-gray-600">${p.viewCount}</td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${p.published}">
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">已发布</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">草稿</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/dynamics?action=edit&id=${p.id}"
                                           class="text-primary hover:underline">编辑</a>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/dynamics" class="inline">
                                            <input type="hidden" name="action" value="toggle">
                                            <input type="hidden" name="id" value="${p.id}">
                                            <input type="hidden" name="published" value="${p.published ? 0 : 1}">
                                            <button type="submit" class="text-gray-500 hover:text-primary">${p.published ? '下线' : '发布'}</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/dynamics" class="inline"
                                              onsubmit="return confirm('确定删除动态「${p.title}」？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${p.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty posts}">
                            <tr><td colspan="8" class="px-4 py-10 text-center text-gray-400">暂无动态，点击右上角「发布动态」添加</td></tr>
                        </c:if>
                    </tbody>
                </table>
                </div>

                <%-- 分页条（保留分类 + 关键词筛选）--%>
                <c:if test="${totalPages > 1}">
                    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-4 py-3 border-t border-gray-100 text-sm">
                        <div class="text-gray-500">第 ${page} / ${totalPages} 页</div>
                        <div class="flex items-center gap-1">
                            <c:url var="prevUrl" value="/admin/dynamics">
                                <c:if test="${not empty categoryFilter}"><c:param name="category" value="${categoryFilter}"/></c:if>
                                <c:if test="${not empty keyword}"><c:param name="q" value="${keyword}"/></c:if>
                                <c:param name="page" value="${page - 1}"/>
                            </c:url>
                            <c:choose>
                                <c:when test="${page > 1}">
                                    <a href="${prevUrl}" class="px-3 py-1.5 rounded border border-gray-200 text-gray-600 hover:text-primary hover:border-primary">上一页</a>
                                </c:when>
                                <c:otherwise>
                                    <span class="px-3 py-1.5 rounded border border-gray-100 text-gray-300 cursor-not-allowed">上一页</span>
                                </c:otherwise>
                            </c:choose>

                            <c:forEach var="i" begin="1" end="${totalPages}">
                                <c:url var="pUrl" value="/admin/dynamics">
                                    <c:if test="${not empty categoryFilter}"><c:param name="category" value="${categoryFilter}"/></c:if>
                                    <c:if test="${not empty keyword}"><c:param name="q" value="${keyword}"/></c:if>
                                    <c:param name="page" value="${i}"/>
                                </c:url>
                                <a href="${pUrl}"
                                   class="px-3 py-1.5 rounded border ${i eq page ? 'bg-primary text-white border-primary' : 'border-gray-200 text-gray-600 hover:text-primary hover:border-primary'}">${i}</a>
                            </c:forEach>

                            <c:url var="nextUrl" value="/admin/dynamics">
                                <c:if test="${not empty categoryFilter}"><c:param name="category" value="${categoryFilter}"/></c:if>
                                <c:if test="${not empty keyword}"><c:param name="q" value="${keyword}"/></c:if>
                                <c:param name="page" value="${page + 1}"/>
                            </c:url>
                            <c:choose>
                                <c:when test="${page < totalPages}">
                                    <a href="${nextUrl}" class="px-3 py-1.5 rounded border border-gray-200 text-gray-600 hover:text-primary hover:border-primary">下一页</a>
                                </c:when>
                                <c:otherwise>
                                    <span class="px-3 py-1.5 rounded border border-gray-100 text-gray-300 cursor-not-allowed">下一页</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </c:if>
            </div>
        </main>
    </div>
</div>
</body>
</html>
