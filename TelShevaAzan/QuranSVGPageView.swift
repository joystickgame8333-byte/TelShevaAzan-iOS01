import Compression
import Foundation
import SwiftUI
import WebKit

/// Displays a pre-shaped Mushaf SVG page from the offline `MushafSVG` bundle.
///
/// The web view is intentionally loaded only once. Page changes replace the SVG
/// inside the existing document, which avoids the blank flash and process churn
/// caused by recreating a `WKWebView` for every swipe.
struct QuranSVGPageView: UIViewRepresentable {
    let pageNumber: Int
    let theme: PrayerVisualTheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.suppressesIncrementalRendering = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.underPageBackgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.allowsLinkPreview = false

        // The SwiftUI reader owns horizontal page swipes. Keeping the renderer
        // non-interactive guarantees that the embedded web view cannot consume
        // the drag before SwiftUI receives it.
        webView.isUserInteractionEnabled = false
        webView.isAccessibilityElement = true
        webView.accessibilityLabel = "صفحة من المصحف الشريف"

        context.coordinator.attach(to: webView)
        webView.loadHTMLString(Self.shellHTML, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.show(
            pageNumber: min(max(pageNumber, 1), 604),
            appearance: Appearance(theme: theme),
            in: webView
        )
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stop()
        webView.stopLoading()
        webView.navigationDelegate = nil
    }
}

extension QuranSVGPageView {
    final class Coordinator: NSObject, WKNavigationDelegate {
        private struct RenderRequest {
            let serial: UInt64
            let pageNumber: Int
            let svg: String
            let appearance: Appearance
        }

        private struct ErrorRequest {
            let serial: UInt64
            let pageNumber: Int
        }

        private typealias PageCompletion = (Result<String, Error>) -> Void

        private let pageCache: NSCache<NSNumber, NSString> = {
            let cache = NSCache<NSNumber, NSString>()
            cache.countLimit = 9
            cache.totalCostLimit = 16 * 1_024 * 1_024
            return cache
        }()

        private let pageLoadQueue: OperationQueue = {
            let queue = OperationQueue()
            queue.name = "com.omaralasam.telshevaazan.quran-svg-loader"
            queue.qualityOfService = .userInitiated
            queue.maxConcurrentOperationCount = 3
            return queue
        }()

        private weak var webView: WKWebView?
        private var shellIsReady = false
        private var stopped = false
        private var serial: UInt64 = 0
        private var requestedPageNumber: Int?
        private var requestedAppearance: Appearance?
        private var pendingRender: RenderRequest?
        private var pendingError: ErrorRequest?
        private var latestRenderRequest: RenderRequest?
        private var pageCompletions: [Int: [PageCompletion]] = [:]
        private var pageOperations: [Int: Operation] = [:]
        private var shellRecoveryAttempts = 0
        private var isShowingFallback = false
        private let maximumShellRecoveryAttempts = 2

        func attach(to webView: WKWebView) {
            self.webView = webView
        }

        fileprivate func show(pageNumber: Int, appearance: Appearance, in webView: WKWebView) {
            guard !stopped else { return }
            self.webView = webView

            guard requestedPageNumber != pageNumber || requestedAppearance != appearance else {
                return
            }

            serial &+= 1
            let requestSerial = serial
            requestedPageNumber = pageNumber
            requestedAppearance = appearance
            pendingRender = nil
            pendingError = nil
            latestRenderRequest = nil
            shellRecoveryAttempts = 0
            isShowingFallback = false
            webView.accessibilityLabel = "صفحة \(pageNumber) من المصحف الشريف"

            loadPage(pageNumber, priority: .veryHigh) { [weak self, weak webView] result in
                guard let self, let webView,
                      !self.stopped,
                      self.serial == requestSerial,
                      self.requestedPageNumber == pageNumber else { return }

                switch result {
                case .success(let svg):
                    let request = RenderRequest(
                        serial: requestSerial,
                        pageNumber: pageNumber,
                        svg: svg,
                        appearance: appearance
                    )
                    self.latestRenderRequest = request
                    self.renderOrDefer(request, in: webView)

                case .failure:
                    self.showError(serial: requestSerial, pageNumber: pageNumber, in: webView)
                }
            }

            prefetch(pageNumber - 1)
            prefetch(pageNumber + 1)
        }

        func stop() {
            stopped = true
            serial &+= 1
            pendingRender = nil
            pendingError = nil
            latestRenderRequest = nil
            pageCompletions.removeAll()
            pageOperations.removeAll()
            pageLoadQueue.cancelAllOperations()
            pageCache.removeAllObjects()
            webView = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !stopped else { return }
            shellIsReady = true

            if let pendingRender {
                self.pendingRender = nil
                render(pendingRender, in: webView)
            } else if let pendingError {
                self.pendingError = nil
                showError(
                    serial: pendingError.serial,
                    pageNumber: pendingError.pageNumber,
                    in: webView
                )
            }
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            recoverFromNavigationFailure(error, in: webView)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            recoverFromNavigationFailure(error, in: webView)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            recoverShell(in: webView, preserving: latestRenderRequest)
        }

        private func renderOrDefer(_ request: RenderRequest, in webView: WKWebView) {
            guard request.serial == serial else { return }
            guard shellIsReady else {
                pendingRender = request
                return
            }
            render(request, in: webView)
        }

        private func render(_ request: RenderRequest, in webView: WKWebView) {
            guard request.serial == serial,
                  request.pageNumber == requestedPageNumber else { return }

            let payload: [String: Any] = [
                "serial": request.serial,
                "page": request.pageNumber,
                "svg": request.svg,
                "background": request.appearance.background,
                "content": request.appearance.content,
                "markers": request.appearance.ayahMarkers
            ]

            guard JSONSerialization.isValidJSONObject(payload),
                  let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else {
                showError(serial: request.serial, pageNumber: request.pageNumber, in: webView)
                return
            }

            webView.evaluateJavaScript("window.renderQuranPage(\(json));") { [weak self, weak webView] _, error in
                guard let self, let webView,
                      !self.stopped,
                      request.serial == self.serial,
                      request.pageNumber == self.requestedPageNumber else { return }

                if error == nil {
                    self.shellRecoveryAttempts = 0
                    self.isShowingFallback = false
                } else {
                    self.recoverShell(in: webView, preserving: request)
                }
            }
        }

        private func showError(serial: UInt64, pageNumber: Int, in webView: WKWebView) {
            guard serial == self.serial else { return }
            guard shellIsReady else {
                pendingError = ErrorRequest(serial: serial, pageNumber: pageNumber)
                return
            }

            let message = "تعذّر تحميل صفحة \(pageNumber) من المصحف"
            let payload = ["message": message]
            guard let messageData = try? JSONSerialization.data(withJSONObject: payload),
                  let messageJSON = String(data: messageData, encoding: .utf8) else { return }
            webView.evaluateJavaScript(
                "window.renderQuranError(\(serial), \(messageJSON).message);"
            ) { [weak self, weak webView] _, error in
                guard let self, let webView,
                      !self.stopped,
                      serial == self.serial,
                      error != nil else { return }
                self.recoverShell(in: webView, preserving: self.latestRenderRequest)
            }
        }

        private func recoverFromNavigationFailure(_ error: Error, in webView: WKWebView) {
            guard !isShowingFallback,
                  (error as NSError).code != NSURLErrorCancelled else { return }
            recoverShell(in: webView, preserving: latestRenderRequest)
        }

        private func recoverShell(in webView: WKWebView, preserving request: RenderRequest?) {
            guard !stopped else { return }

            guard shellRecoveryAttempts < maximumShellRecoveryAttempts else {
                shellIsReady = false
                pendingRender = nil
                pendingError = nil
                latestRenderRequest = nil
                isShowingFallback = true
                webView.stopLoading()
                webView.loadHTMLString(QuranSVGPageView.fallbackHTML, baseURL: nil)
                return
            }

            shellRecoveryAttempts += 1
            shellIsReady = false
            isShowingFallback = false
            if let request,
               request.serial == serial,
               request.pageNumber == requestedPageNumber {
                latestRenderRequest = request
                pendingRender = request
            }
            pendingError = nil
            webView.stopLoading()
            webView.loadHTMLString(QuranSVGPageView.shellHTML, baseURL: nil)
        }

        private func prefetch(_ pageNumber: Int) {
            guard (1...604).contains(pageNumber) else { return }
            loadPage(pageNumber, priority: .low) { _ in }
        }

        private func loadPage(
            _ pageNumber: Int,
            priority: Operation.QueuePriority,
            completion: @escaping PageCompletion
        ) {
            let cacheKey = NSNumber(value: pageNumber)
            if let cached = pageCache.object(forKey: cacheKey) {
                completion(.success(cached as String))
                return
            }

            if pageCompletions[pageNumber] != nil {
                pageCompletions[pageNumber, default: []].append(completion)
                if priority == .veryHigh {
                    pageOperations[pageNumber]?.queuePriority = .veryHigh
                }
                return
            }
            pageCompletions[pageNumber] = [completion]

            let operation = BlockOperation { [weak self] in
                let result = Result { try Self.readPage(pageNumber) }
                OperationQueue.main.addOperation { [weak self] in
                    guard let self, !self.stopped else { return }

                    if case .success(let svg) = result {
                        self.pageCache.setObject(
                            svg as NSString,
                            forKey: cacheKey,
                            cost: svg.utf8.count
                        )
                    }

                    let completions = self.pageCompletions.removeValue(forKey: pageNumber) ?? []
                    self.pageOperations.removeValue(forKey: pageNumber)
                    completions.forEach { $0(result) }
                }
            }
            operation.queuePriority = priority
            pageOperations[pageNumber] = operation
            pageLoadQueue.addOperation(operation)
        }

        private static func readPage(_ pageNumber: Int) throws -> String {
            let resourceName = String(format: "p%03d", pageNumber)
            let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "qsvg",
                subdirectory: "MushafSVG"
            ) ?? Bundle.main.url(
                forResource: resourceName,
                withExtension: "qsvg",
                subdirectory: "Quran/MushafSVG"
            ) ?? Bundle.main.url(
                forResource: resourceName,
                withExtension: "qsvg"
            )

            guard let url else { throw QuranSVGError.missingPage(pageNumber) }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return try decodeQSVG(data)
        }

        /// QSVG format: four-byte big-endian uncompressed byte count followed
        /// by a zlib stream containing one UTF-8 SVG document.
        private static func decodeQSVG(_ data: Data) throws -> String {
            // The package stores a complete RFC 1950 zlib stream. Apple's
            // `COMPRESSION_ZLIB` decoder consumes the raw RFC 1951 DEFLATE
            // payload, so skip the two-byte zlib header and four-byte Adler-32
            // trailer after validating the wrapper.
            guard data.count > 10 else { throw QuranSVGError.invalidHeader }

            let expectedSize = data.prefix(4).reduce(UInt32(0)) { partial, byte in
                (partial << 8) | UInt32(byte)
            }
            guard expectedSize > 0, expectedSize <= 8 * 1_024 * 1_024 else {
                throw QuranSVGError.invalidDecodedSize(Int(expectedSize))
            }

            let compressionMethodAndFlags = Int(data[4]) * 256 + Int(data[5])
            guard (data[4] & 0x0F) == 8,
                  compressionMethodAndFlags % 31 == 0,
                  (data[5] & 0x20) == 0 else {
                throw QuranSVGError.invalidHeader
            }

            var decoded = Data(count: Int(expectedSize))
            let decodedCount = decoded.withUnsafeMutableBytes { destinationBytes -> Int in
                guard let destination = destinationBytes.bindMemory(to: UInt8.self).baseAddress else {
                    return 0
                }

                return data.withUnsafeBytes { sourceBytes -> Int in
                    guard let sourceStart = sourceBytes.bindMemory(to: UInt8.self).baseAddress else {
                        return 0
                    }
                    return compression_decode_buffer(
                        destination,
                        Int(expectedSize),
                        sourceStart.advanced(by: 6),
                        data.count - 10,
                        nil,
                        COMPRESSION_ZLIB
                    )
                }
            }

            guard decodedCount == Int(expectedSize) else {
                throw QuranSVGError.decompressionFailed(
                    expected: Int(expectedSize),
                    actual: decodedCount
                )
            }
            decoded.count = decodedCount

            guard let svg = String(data: decoded, encoding: .utf8),
                  svg.range(of: "<svg", options: [.caseInsensitive]) != nil else {
                throw QuranSVGError.invalidSVG
            }
            return svg
        }
    }
}

fileprivate extension QuranSVGPageView {
    struct Appearance: Equatable {
        let background: String
        let content: String
        let ayahMarkers: String

        init(theme: PrayerVisualTheme) {
            if theme.isNightTheme {
                background = "#02080D"
                content = "#FAFAF7"
                ayahMarkers = "#B7BDC2"
            } else {
                background = "#FEFBF7"
                content = "#0D0C0A"
                ayahMarkers = "#A47746"
            }
        }
    }

    enum QuranSVGError: Error {
        case missingPage(Int)
        case invalidHeader
        case invalidDecodedSize(Int)
        case decompressionFailed(expected: Int, actual: Int)
        case invalidSVG
    }

    static let fallbackHTML = """
    <!doctype html>
    <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
      <style>
        html, body {
          width: 100%;
          height: 100%;
          margin: 0;
          background: transparent;
        }
        body {
          display: flex;
          align-items: center;
          justify-content: center;
          color: rgba(35, 31, 28, 0.72);
          font: 700 15px/1.7 -apple-system, BlinkMacSystemFont, sans-serif;
          text-align: center;
        }
        @media (prefers-color-scheme: dark) {
          body { color: rgba(250, 250, 247, 0.72); }
        }
      </style>
    </head>
    <body>تعذّر عرض صفحة المصحف. انتقل إلى صفحة أخرى ثم أعد المحاولة.</body>
    </html>
    """

    static let shellHTML = """
    <!doctype html>
    <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
      <style>
        :root {
          --page-background: transparent;
          --content-color: #0D0C0A;
          --ayah-marker-color: #A47746;
        }
        * { box-sizing: border-box; }
        html, body {
          width: 100%;
          height: 100%;
          margin: 0;
          padding: 0;
          overflow: hidden;
          overscroll-behavior: none;
          background: var(--page-background);
          -webkit-user-select: none;
          user-select: none;
          -webkit-touch-callout: none;
        }
        body, #stage {
          pointer-events: none;
          touch-action: none;
        }
        #stage {
          width: 100%;
          height: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
          background: var(--page-background);
        }
        #stage > svg {
          display: block;
          width: 100% !important;
          height: 100% !important;
          max-width: 100%;
          max-height: 100%;
          overflow: visible;
          background: transparent !important;
        }
        #stage #content,
        #stage #content * {
          fill: var(--content-color) !important;
        }
        #stage #ayah_markers,
        #stage #ayah_markers * {
          fill: var(--ayah-marker-color) !important;
        }
        #error {
          display: none;
          width: min(88%, 360px);
          color: var(--content-color);
          font: 700 15px/1.7 -apple-system, BlinkMacSystemFont, sans-serif;
          text-align: center;
        }
        body.failed #stage { display: none; }
        body.failed #error { display: block; }
        body.failed {
          display: flex;
          align-items: center;
          justify-content: center;
        }
      </style>
    </head>
    <body>
      <main id="stage" aria-live="off"></main>
      <div id="error" role="status"></div>
      <script>
        (() => {
          let latestSerial = 0;

          function applyPalette(payload) {
            const root = document.documentElement.style;
            root.setProperty('--page-background', payload.background);
            root.setProperty('--content-color', payload.content);
            root.setProperty('--ayah-marker-color', payload.markers);
          }

          window.renderQuranPage = payload => {
            if (!payload || payload.serial < latestSerial) return;
            latestSerial = payload.serial;
            applyPalette(payload);

            const stage = document.getElementById('stage');
            const parsed = new DOMParser().parseFromString(payload.svg, 'image/svg+xml');
            const svg = parsed.documentElement;
            if (!svg || svg.localName !== 'svg' || parsed.querySelector('parsererror')) {
              window.renderQuranError(payload.serial, 'تعذّر عرض صفحة المصحف');
              return;
            }

            svg.removeAttribute('width');
            svg.removeAttribute('height');
            svg.setAttribute('width', '100%');
            svg.setAttribute('height', '100%');
            svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');
            svg.setAttribute('focusable', 'false');
            svg.setAttribute('aria-hidden', 'true');

            stage.replaceChildren(document.importNode(svg, true));
            document.body.classList.remove('failed');
            document.getElementById('error').textContent = '';
            document.body.dataset.page = String(payload.page);
          };

          window.renderQuranError = (serial, message) => {
            if (serial < latestSerial) return;
            latestSerial = serial;
            document.getElementById('error').textContent = message || 'تعذّر عرض صفحة المصحف';
            document.body.classList.add('failed');
          };
        })();
      </script>
    </body>
    </html>
    """
}
