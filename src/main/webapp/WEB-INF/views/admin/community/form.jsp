<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="active" value="community"/>
<c:set var="isEdit" value="${formMode eq 'edit'}"/>
<c:set var="pageTitle" value="${isEdit ? '编辑问答' : '新增问答'}"/>
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
                <a href="${pageContext.request.contextPath}/admin/community" class="hover:text-primary">社区问答</a>
                <span class="mx-2">/</span>
                <span class="text-gray-900">${pageTitle}</span>
            </div>

            <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl">
                <c:if test="${not empty error}">
                    <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                        <i class="fa-solid fa-circle-exclamation"></i> ${error}
                    </div>
                </c:if>

                <form action="${pageContext.request.contextPath}/admin/community" method="post" class="space-y-5">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="${question.id}">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">URL 标识 <span class="text-red-500">*</span></label>
                            <input type="text" name="slug" value="${question.slug}" required
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary font-mono"
                                   placeholder="如 public-ip">
                            <p class="text-xs text-gray-400 mt-1">前台详情页 ?question= 取此值，全站唯一</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">状态</label>
                            <select name="status"
                                    class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <option value="published" ${question.status eq 'published' ? 'selected' : ''}>已发布（前台可见）</option>
                                <option value="pending" ${question.status eq 'pending' ? 'selected' : ''}>待审核</option>
                                <option value="closed" ${question.status eq 'closed' ? 'selected' : ''}>已关闭</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">标题 <span class="text-red-500">*</span></label>
                        <input type="text" name="title" value="${question.title}" required
                               class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                               placeholder="一句话描述问题">
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">分类</label>
                            <input type="text" name="category" value="${question.category}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 云服务器 ECS">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">类型</label>
                            <select name="type"
                                    class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                                <option ${question.type eq '问题求助' ? 'selected' : ''}>问题求助</option>
                                <option ${question.type eq '经验分享' ? 'selected' : ''}>经验分享</option>
                                <option ${question.type eq '教程文章' ? 'selected' : ''}>教程文章</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">角标 <span class="text-gray-400 text-xs">(如 连接/计费)</span></label>
                            <input type="text" name="tag" value="${question.tag}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="如 连接">
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">列表摘要</label>
                        <input type="text" name="summary" value="${question.summary}"
                               class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                               placeholder="问答列表上展示的摘要">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">正文</label>
                        <textarea name="content" rows="7"
                                  class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary resize-y"
                                  placeholder="问题描述，段落之间用空行分隔">${question.content}</textarea>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1.5">推荐处理 <span class="text-gray-400 text-xs">(高亮块，可空)</span></label>
                        <textarea name="recommendation" rows="3"
                                  class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary resize-y"
                                  placeholder="官方建议的处理方式">${question.recommendation}</textarea>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">发表人</label>
                            <input type="text" name="authorName" value="${question.authorName}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1.5">联系方式 <span class="text-gray-400 text-xs">(用户提交，仅后台可见)</span></label>
                            <input type="text" name="contact" value="${question.contact}"
                                   class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary">
                        </div>
                    </div>

                    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-6 py-2.5 text-sm font-medium transition shadow-sm">
                            ${isEdit ? '保存修改' : '创建问答'}
                        </button>
                        <a href="${pageContext.request.contextPath}/admin/community"
                           class="border border-gray-300 bg-white text-gray-700 rounded px-5 py-2.5 text-sm hover:text-primary hover:border-primary transition">
                            取消
                        </a>
                    </div>
                </form>
            </div>

            <%-- 回复管理（仅编辑态） --%>
            <c:if test="${isEdit}">
                <div class="bg-white rounded-xl border border-gray-200 shadow-sm p-6 max-w-3xl mt-6">
                    <h3 class="text-base font-bold text-gray-900 mb-4">社区回复（${question.replies.size()}）</h3>

                    <div class="space-y-3 mb-6">
                        <c:forEach var="r" items="${question.replies}">
                            <div class="border border-gray-100 rounded-lg p-4 flex items-start justify-between gap-3">
                                <div>
                                    <div class="flex items-center gap-2 text-sm">
                                        <span class="font-medium text-gray-900">${r.authorName}</span>
                                        <c:if test="${r.official}">
                                            <span class="bg-blue-50 text-primary text-xs px-2 py-0.5 rounded">官方</span>
                                        </c:if>
                                        <span class="text-xs text-gray-400">
                                            <fmt:formatDate value="${r.createdAt}" pattern="yyyy-MM-dd HH:mm"/>
                                        </span>
                                        <span class="text-xs text-gray-400">· 赞 ${r.likeCount}</span>
                                    </div>
                                    <p class="text-sm text-gray-600 mt-2 leading-6">${r.content}</p>
                                </div>
                                <form method="post" action="${pageContext.request.contextPath}/admin/community"
                                      onsubmit="return confirm('删除该回复？');">
                                    <input type="hidden" name="action" value="delReply">
                                    <input type="hidden" name="id" value="${question.id}">
                                    <input type="hidden" name="replyId" value="${r.id}">
                                    <button type="submit" class="text-red-500 text-sm hover:underline whitespace-nowrap">删除</button>
                                </form>
                            </div>
                        </c:forEach>
                        <c:if test="${empty question.replies}">
                            <p class="text-sm text-gray-400">暂无回复</p>
                        </c:if>
                    </div>

                    <form method="post" action="${pageContext.request.contextPath}/admin/community" class="border-t border-gray-100 pt-5 space-y-3">
                        <input type="hidden" name="action" value="addReply">
                        <input type="hidden" name="id" value="${question.id}">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <input type="text" name="authorName" value="云极技术支持"
                                   class="border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                                   placeholder="回复人">
                            <label class="inline-flex items-center text-sm text-gray-700">
                                <input type="checkbox" name="official" value="1" checked class="w-4 h-4 mr-2 accent-primary">
                                标记为官方回复
                            </label>
                        </div>
                        <textarea name="content" rows="3" required
                                  class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary resize-y"
                                  placeholder="输入回复内容"></textarea>
                        <button type="submit"
                                class="bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                            追加回复
                        </button>
                    </form>
                </div>
            </c:if>
        </main>
    </div>
</div>
</body>
</html>
