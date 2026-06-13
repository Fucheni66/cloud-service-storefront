<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <%@ include file="fragments/head.jspf" %>
    <title>管理员登录 · AJOU 管理后台</title>
</head>
<body class="bg-bg-gray text-gray-800 font-sans antialiased min-h-screen flex flex-col">
<main class="flex-grow flex items-center justify-center px-4 py-12">
    <section class="w-full max-w-md bg-white border border-gray-200 rounded-xl shadow-sm p-8">
        <%-- Logo + 标题 --%>
        <div class="text-center mb-6">
            <a href="${pageContext.request.contextPath}/" class="inline-flex items-center">
                <i class="fa-solid fa-cloud text-primary text-2xl"></i>
                <span class="ml-2 text-xl font-bold text-gray-900 tracking-[0.05em]">AJOU</span>
            </a>
            <h1 class="mt-4 text-2xl font-bold text-gray-900">管理员登录</h1>
            <p class="mt-1 text-sm text-gray-500">登录 AJOU 云服务管理后台</p>
        </div>

        <%-- 错误提示 --%>
        <c:if test="${not empty error}">
            <div class="mb-4 rounded bg-red-50 border border-red-200 text-red-500 text-sm px-4 py-2.5">
                <i class="fa-solid fa-circle-exclamation"></i> ${error}
            </div>
        </c:if>

        <form action="${pageContext.request.contextPath}/admin/login" method="post" class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">用户名</label>
                <input type="text" name="username" value="${username}" required autofocus
                       class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                       placeholder="请输入用户名">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1.5">密码</label>
                <input type="password" name="password" required
                       class="w-full border border-gray-300 rounded px-3 py-2.5 text-sm focus:outline-none focus:border-primary"
                       placeholder="请输入密码">
            </div>
            <button type="submit"
                    class="w-full bg-primary hover:bg-primary-hover text-white rounded px-5 py-2.5 text-sm font-medium transition shadow-sm">
                登录
            </button>
        </form>
    </section>
</main>
</body>
</html>
