import SwiftUI
import WebKit

struct QuranQCFPrototypePageView: UIViewRepresentable {
    let theme: PrayerVisualTheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        webView.accessibilityLabel = "صفحة 293 من المصحف الشريف"
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let appearanceKey = theme.isNightTheme ? "night" : "day"
        guard context.coordinator.appearanceKey != appearanceKey else { return }
        context.coordinator.appearanceKey = appearanceKey
        webView.loadHTMLString(Self.html(for: theme), baseURL: nil)
    }

    final class Coordinator {
        var appearanceKey: String?
    }

    private static func html(for theme: PrayerVisualTheme) -> String {
        do {
            let payload = try loadPayload()
            let qcfFont = try resourceData(named: "p293", fileExtension: "woff2")
            let unicodeFont = try resourceData(named: "UthmanicHafs1Ver18", fileExtension: "ttf")
            return document(
                payload: payload,
                qcfFontBase64: qcfFont.base64EncodedString(),
                unicodeFontBase64: unicodeFont.base64EncodedString(),
                isNight: theme.isNightTheme
            )
        } catch {
            return errorDocument(isNight: theme.isNightTheme)
        }
    }

    private static func loadPayload() throws -> QCFPrototypePayload {
        let data = try resourceData(named: "qcf-page-293-v2", fileExtension: "json")
        return try JSONDecoder().decode(QCFPrototypePayload.self, from: data)
    }

    private static func resourceData(named name: String, fileExtension: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            throw QCFPrototypeError.missingResource
        }
        return try Data(contentsOf: url, options: .mappedIfSafe)
    }

    private static func document(
        payload: QCFPrototypePayload,
        qcfFontBase64: String,
        unicodeFontBase64: String,
        isNight: Bool
    ) -> String {
        let background = isNight ? "#02080d" : "#fbf7e9"
        let text = isNight ? "#fbfbfb" : "#1b1812"
        let muted = isNight ? "#8f969c" : "#776f60"
        let ornament = isNight ? "#656b70" : "#887e69"
        let headerFill = isNight ? "#0b1115" : "#f3eddd"

        let lines = payload.lines
            .sorted { $0.number < $1.number }
            .map { lineHTML($0) }
            .joined()

        return """
        <!doctype html>
        <html lang="ar" dir="rtl">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
          <style>
            @font-face {
              font-family: 'QCF293';
              src: url(data:font/woff2;base64,\(qcfFontBase64)) format('woff2');
              font-weight: normal;
              font-style: normal;
            }
            @font-face {
              font-family: 'UthmanicHafs';
              src: url(data:font/ttf;base64,\(unicodeFontBase64)) format('truetype');
              font-weight: normal;
              font-style: normal;
            }
            :root {
              --page-background: \(background);
              --page-text: \(text);
              --page-muted: \(muted);
              --page-ornament: \(ornament);
              --header-fill: \(headerFill);
              --qcf-size: 32px;
            }
            * { box-sizing: border-box; }
            html, body {
              width: 100%;
              height: 100%;
              margin: 0;
              padding: 0;
              overflow: hidden;
              background: transparent;
              color: var(--page-text);
              -webkit-font-smoothing: antialiased;
              text-rendering: optimizeLegibility;
            }
            .mushaf-page {
              width: 100%;
              height: 100%;
              padding: 0 3px;
              display: grid;
              grid-template-rows: repeat(15, minmax(0, 1fr));
              align-items: stretch;
              background: var(--page-background);
            }
            .mushaf-line {
              width: 100%;
              min-width: 0;
              display: flex;
              align-items: center;
              justify-content: center;
              overflow: visible;
              white-space: nowrap;
              text-align: center;
            }
            .mushaf-line.text {
              direction: rtl;
              font-family: 'QCF293';
              font-size: var(--qcf-size);
              font-weight: normal;
              line-height: 1;
              word-spacing: 1px;
            }
            .qcf-token {
              display: inline-block;
              flex: 0 0 auto;
            }
            .surah-frame {
              width: calc(100% - 12px);
              height: 76%;
              min-height: 31px;
              padding: 0 13px;
              display: grid;
              grid-template-columns: 1fr auto 1fr;
              align-items: center;
              gap: 10px;
              border: 1px solid var(--page-ornament);
              outline: 1px solid var(--page-ornament);
              outline-offset: -4px;
              border-radius: 4px;
              background: var(--header-fill);
            }
            .surah-frame .title {
              padding: 0 10px;
              font-family: 'UthmanicHafs';
              font-size: 23px;
              line-height: 1;
              color: var(--page-text);
            }
            .surah-frame .ornament {
              height: 1px;
              position: relative;
              background: var(--page-ornament);
            }
            .surah-frame .ornament::after {
              content: '';
              position: absolute;
              top: 50%;
              width: 7px;
              height: 7px;
              background: var(--header-fill);
              border: 1px solid var(--page-ornament);
              transform: translateY(-50%) rotate(45deg);
            }
            .surah-frame .ornament:first-child::after { right: -2px; }
            .surah-frame .ornament:last-child::after { left: -2px; }
            .mushaf-line.bismillah {
              direction: rtl;
              font-family: 'UthmanicHafs';
              font-size: 27px;
              line-height: 1;
              color: var(--page-text);
            }
          </style>
        </head>
        <body>
          <main class="mushaf-page" aria-label="صفحة \(payload.page) من المصحف الشريف">
            \(lines)
          </main>
          <script>
            function fitQCFPage() {
              const page = document.querySelector('.mushaf-page');
              const lines = Array.from(document.querySelectorAll('.mushaf-line.text'));
              const available = page.clientWidth - 6;
              let size = Math.min(34, Math.max(25, page.clientWidth * 0.082));
              const apply = () => document.documentElement.style.setProperty('--qcf-size', size + 'px');
              apply();
              while (size > 21 && lines.some(line => line.scrollWidth > available + 0.5)) {
                size -= 0.25;
                apply();
              }
            }
            document.fonts.ready.then(fitQCFPage);
            window.addEventListener('resize', fitQCFPage);
          </script>
        </body>
        </html>
        """
    }

    private static func lineHTML(_ line: QCFPrototypeLine) -> String {
        switch line.kind {
        case "surah":
            return """
            <section class="mushaf-line surah" data-line="\(line.number)">
              <div class="surah-frame">
                <span class="ornament"></span>
                <span class="title">\(escaped(line.text))</span>
                <span class="ornament"></span>
              </div>
            </section>
            """

        case "bismillah":
            return "<section class=\"mushaf-line bismillah\" data-line=\"\(line.number)\">\(escaped(line.text))</section>"

        default:
            let tokens = line.tokens.map { token in
                "<span class=\"qcf-token \(escaped(token.kind))\">\(escaped(token.qcf))</span>"
            }.joined(separator: " ")
            return "<section class=\"mushaf-line text\" data-line=\"\(line.number)\">\(tokens)</section>"
        }
    }

    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func errorDocument(isNight: Bool) -> String {
        let background = isNight ? "#02080d" : "#fbf7e9"
        let text = isNight ? "#fbfbfb" : "#1b1812"
        return """
        <html lang="ar" dir="rtl"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head>
        <body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:\(background);color:\(text);font-family:-apple-system;text-align:center">
          تعذّر تحميل خط صفحة المصحف التجريبية
        </body></html>
        """
    }
}

private struct QCFPrototypePayload: Decodable {
    let page: Int
    let lines: [QCFPrototypeLine]
}

private struct QCFPrototypeLine: Decodable {
    let number: Int
    let kind: String
    let text: String
    let tokens: [QCFPrototypeToken]
}

private struct QCFPrototypeToken: Decodable {
    let kind: String
    let qcf: String
}

private enum QCFPrototypeError: Error {
    case missingResource
}
