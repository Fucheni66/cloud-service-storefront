<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="active" value="community"/>
<c:set var="pageTitle" value="开发者社区"/>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="../fragments/head.jspf" %>
    <title>开发者社区 · AJOU 云服务商后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased">
<div class="flex min-h-screen">
    <%@ include file="../fragments/sidebar.jspf" %>

    <div class="flex-1 flex flex-col min-w-0">
        <%@ include file="../fragments/topbar.jspf" %>

        <main class="flex-1 p-6">
            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900">社区问答管理</h2>
                    <p class="text-sm text-gray-500 mt-1">
                        共 ${questions.size()} 条
                        <c:if test="${pendingCount > 0}">
                            · <span class="text-orange-600 font-medium">${pendingCount} 条待审核</span>
                        </c:if>
                    </p>
                </div>
                <a href="${pageContext.request.contextPath}/admin/community?action=new"
                   class="inline-flex items-center bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                    <i class="fa-solid fa-plus mr-2"></i> 新增问答
                </a>
            </div>

            <%-- 状态筛选 --%>
            <div class="flex items-center gap-2 mb-4 text-sm">
                <a href="${pageContext.request.contextPath}/admin/community"
                   class="px-3 py-1.5 rounded ${empty statusFilter ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-gray-600 hover:text-primary'}">全部</a>
                <a href="${pageContext.request.contextPath}/admin/community?status=pending"
                   class="px-3 py-1.5 rounded ${statusFilter eq 'pending' ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-gray-600 hover:text-primary'}">待审核</a>
                <a href="${pageContext.request.contextPath}/admin/community?status=published"
                   class="px-3 py-1.5 rounded ${statusFilter eq 'published' ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-gray-600 hover:text-primary'}">已发布</a>
                <a href="${pageContext.request.contextPath}/admin/community?status=closed"
                   class="px-3 py-1.5 rounded ${statusFilter eq 'closed' ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-gray-600 hover:text-primary'}">已关闭</a>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div style="overflow-x:auto">
                <table class="w-full text-sm whitespace-nowrap" style="min-width:1040px">
                    <thead>
                        <tr class="text-left text-gray-500 bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 font-medium">标题</th>
                            <th class="px-4 py-3 font-medium">分类</th>
                            <th class="px-4 py-3 font-medium">类型</th>
                            <th class="px-4 py-3 font-medium">回复</th>
                            <th class="px-4 py-3 font-medium">状态</th>
                            <th class="px-4 py-3 font-medium text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="q" items="${questions}">
                            <tr class="border-b border-gray-50 hover:bg-gray-50/60">
                                <td class="px-4 py-3" style="white-space:normal;min-width:280px;max-width:460px">
                                    <div class="font-medium text-gray-900">${q.title}</div>
                                    <div class="text-xs text-gray-400 font-mono">${q.slug}</div>
                                </td>
                                <td class="px-4 py-3 text-gray-600">${q.category}</td>
                                <td class="px-4 py-3 text-gray-600">${q.type}</td>
                                <td class="px-4 py-3 text-gray-600">${q.replyCount}</td>
                                <td class="px-4 py-3">
                                    <c:choose>
                                        <c:when test="${q.status eq 'published'}">
                                            <span class="text-xs bg-green-50 text-green-600 border border-green-200 rounded-full px-2 py-0.5">已发布</span>
                                        </c:when>
                                        <c:when test="${q.status eq 'pending'}">
                                            <span class="text-xs bg-orange-50 text-orange-600 border border-orange-200 rounded-full px-2 py-0.5">待审核</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="text-xs bg-gray-100 text-gray-500 border border-gray-200 rounded-full px-2 py-0.5">已关闭</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-2">
                                        <a href="${pageContext.request.contextPath}/admin/community?action=edit&id=${q.id}"
                                           class="text-primary hover:underline">编辑/回复</a>
                                        <c:if test="${q.status ne 'published'}">
                                            <form method="post" action="${pageContext.request.contextPath}/admin/community" class="inline">
                                                <input type="hidden" name="action" value="status">
                                                <input type="hidden" name="id" value="${q.id}">
                                                <input type="hidden" name="status" value="published">
                                                <button type="submit" class="text-green-600 hover:underline">发布</button>
                                            </form>
                                        </c:if>
                                        <c:if test="${q.status eq 'published'}">
                                            <form method="post" action="${pageContext.request.contextPath}/admin/community" class="inline">
                                                <input type="hidden" name="action" value="status">
                                                <input type="hidden" name="id" value="${q.id}">
                                                <input type="hidden" name="status" value="closed">
                                                <button type="submit" class="text-gray-500 hover:text-primary">关闭</button>
                                            </form>
                                        </c:if>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/community" class="inline"
                                              onsubmit="return confirm('确定删除问答「${q.title}」及其全部回复？');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="id" value="${q.id}">
                                            <button type="submit" class="text-red-500 hover:underline">删除</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty questions}">
                            <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400">暂无问答</td></tr>
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
