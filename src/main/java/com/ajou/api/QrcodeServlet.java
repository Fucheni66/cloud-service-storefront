package com.ajou.api;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.OutputStream;
import java.util.EnumMap;
import java.util.Map;

/**
 * 二维码图片（前台路径兼容 PHP /qrcode.php）。
 *
 * <p>把 {@code url} 参数（支付宝当面付返回的 qr_code 支付链接）编码成<strong>真实可扫描</strong>的
 * 二维码 PNG，由前台 {@code <img src="/qrcode.php?url=...&size=220">} 直接展示，支付宝/微信均可识别。</p>
 */
@WebServlet("/qrcode.php")
public class QrcodeServlet extends HttpServlet {

    private static final int BLACK = 0xFF000000;
    private static final int WHITE = 0xFFFFFFFF;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String url = req.getParameter("url");
        int size = clampSize(parseInt(req.getParameter("size"), 220));

        if (url == null || url.isBlank()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "缺少 url 参数");
            return;
        }

        BufferedImage image;
        try {
            image = encode(url, size);
        } catch (WriterException e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "二维码生成失败");
            return;
        }

        resp.setContentType("image/png");
        resp.setHeader("Cache-Control", "no-store");
        try (OutputStream out = resp.getOutputStream()) {
            ImageIO.write(image, "png", out);
        }
    }

    /** 用 ZXing 把文本编码为 QR 位图，再转成黑白 BufferedImage。 */
    private BufferedImage encode(String content, int size) throws WriterException {
        Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        hints.put(EncodeHintType.MARGIN, 1);

        BitMatrix matrix = new QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, size, size, hints);
        int width = matrix.getWidth();
        int height = matrix.getHeight();
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                image.setRGB(x, y, matrix.get(x, y) ? BLACK : WHITE);
            }
        }
        return image;
    }

    private int clampSize(int s) {
        return Math.max(80, Math.min(600, s));
    }

    private int parseInt(String s, int def) {
        try {
            return s == null ? def : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
