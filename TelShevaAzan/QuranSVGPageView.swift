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
    let surahLineNumbers: [Int]

    init(
        pageNumber: Int,
        theme: PrayerVisualTheme,
        surahLineNumbers: [Int] = []
    ) {
        self.pageNumber = pageNumber
        self.theme = theme
        self.surahLineNumbers = surahLineNumbers
    }

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
            surahLineNumbers: surahLineNumbers,
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
            let surahLineNumbers: [Int]
        }

        private struct ErrorRequest {
            let serial: UInt64
            let pageNumber: Int
        }

        private typealias PageCompletion = (Result<String, Error>) -> Void

        private static let pageCache: NSCache<NSNumber, NSString> = {
            let cache = NSCache<NSNumber, NSString>()
            cache.countLimit = 7
            cache.totalCostLimit = 20 * 1_024 * 1_024
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
        private var requestedSurahLineNumbers: [Int] = []
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

        fileprivate func show(
            pageNumber: Int,
            appearance: Appearance,
            surahLineNumbers: [Int],
            in webView: WKWebView
        ) {
            guard !stopped else { return }
            self.webView = webView

            let validSurahLineNumbers = surahLineNumbers
                .filter { (1...15).contains($0) }
                .sorted()

            guard requestedPageNumber != pageNumber
                    || requestedAppearance != appearance
                    || requestedSurahLineNumbers != validSurahLineNumbers else {
                return
            }

            serial &+= 1
            let requestSerial = serial
            requestedPageNumber = pageNumber
            requestedAppearance = appearance
            requestedSurahLineNumbers = validSurahLineNumbers
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
                        appearance: appearance,
                        surahLineNumbers: validSurahLineNumbers
                    )
                    self.latestRenderRequest = request
                    self.renderOrDefer(request, in: webView)

                case .failure:
                    self.showError(serial: requestSerial, pageNumber: pageNumber, in: webView)
                }
            }

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
                "markers": request.appearance.ayahMarkers,
                "ornament": request.appearance.ornament,
                "surahLines": request.surahLineNumbers
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

        private func loadPage(
            _ pageNumber: Int,
            priority: Operation.QueuePriority,
            completion: @escaping PageCompletion
        ) {
            let cacheKey = NSNumber(value: pageNumber)
            if let cached = Self.pageCache.object(forKey: cacheKey) {
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
                        Self.pageCache.setObject(
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
        let ornament: String

        init(theme: PrayerVisualTheme) {
            if theme.isNightTheme {
                background = "transparent"
                content = "#FAFAF7"
                ayahMarkers = "#B7BDC2"
                ornament = "#777D84"
            } else {
                background = "transparent"
                content = "#0D0C0A"
                ayahMarkers = "#A47746"
                ornament = "#A47746"
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
          --ornament-color: #A47746;
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
        #stage #surah_ornaments,
        #stage #surah_ornaments * {
          vector-effect: non-scaling-stroke;
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
            root.setProperty('--ornament-color', payload.ornament);
          }

          function artworkViewBox(svg, originalViewBox) {
            if (!originalViewBox || Number(originalViewBox.width) < 300) return null;

            const rootGroups = Array.from(svg.children)
              .filter(node => node.localName === 'g' && typeof node.getBBox === 'function');
            if (rootGroups.length === 0) return null;

            try {
              const corners = rootGroups.flatMap(group => {
                const bounds = group.getBBox();
                const transform = group.transform.baseVal.consolidate();
                const matrix = transform ? transform.matrix : svg.createSVGMatrix();
                return [
                  [bounds.x, bounds.y],
                  [bounds.x + bounds.width, bounds.y],
                  [bounds.x, bounds.y + bounds.height],
                  [bounds.x + bounds.width, bounds.y + bounds.height]
                ].map(([x, y]) => ({
                  x: matrix.a * x + matrix.c * y + matrix.e,
                  y: matrix.b * x + matrix.d * y + matrix.f
                }));
              });

              const minimumX = Math.min(...corners.map(point => point.x));
              const maximumX = Math.max(...corners.map(point => point.x));
              const minimumY = Math.min(...corners.map(point => point.y));
              const maximumY = Math.max(...corners.map(point => point.y));
              // The QCF paths include delicate tashkeel close to the page edge.
              // A generous safety margin makes the crop remove only genuinely
              // empty source space and never clips Qur'anic artwork.
              const paddingX = 12;
              const paddingY = 14;
              const x = Math.max(originalViewBox.x, minimumX - paddingX);
              const y = Math.max(originalViewBox.y, minimumY - paddingY);
              const right = Math.min(
                originalViewBox.x + originalViewBox.width,
                maximumX + paddingX
              );
              const bottom = Math.min(
                originalViewBox.y + originalViewBox.height,
                maximumY + paddingY
              );
              const width = right - x;
              const height = bottom - y;

              return width >= 300 && height >= 490
                ? { x, y, width, height }
                : null;
            } catch (_) {
              return null;
            }
          }

          function appendSurahOrnaments(svg, lineNumbers, viewBox) {
            if (!Array.isArray(lineNumbers) || lineNumbers.length === 0) return;
            if (!viewBox || Number(viewBox.width) < 300) return;

            const namespace = 'http://www.w3.org/2000/svg';
            const group = document.createElementNS(namespace, 'g');
            group.setAttribute('id', 'surah_ornaments');
            group.setAttribute('fill', 'none');
            group.setAttribute('stroke', 'var(--ornament-color)');
            group.setAttribute('stroke-linecap', 'round');
            group.setAttribute('stroke-linejoin', 'round');

            const left = viewBox.x + 1.5;
            const right = viewBox.x + viewBox.width - 1.5;
            const width = Math.max(0, right - left);
            const centerX = viewBox.x + viewBox.width / 2;
              const centerPlateWidth = Math.min(138, viewBox.width * 0.42);
            const centerLeft = centerX - centerPlateWidth / 2;
            const centerRight = centerX + centerPlateWidth / 2;

            function element(name, attributes) {
              const node = document.createElementNS(namespace, name);
              Object.entries(attributes).forEach(([key, value]) => {
                node.setAttribute(key, String(value));
              });
              return node;
            }

            lineNumbers.forEach(lineNumber => {
              const numericLine = Number(lineNumber);
              if (!Number.isFinite(numericLine) || numericLine < 1 || numericLine > 15) return;

              // Madani 15-line pages use stable baselines: line one is at
              // roughly 29.5 and the following baselines are 35.85 units apart.
              const centerY = 29.5 + (numericLine - 1) * 35.85;
              const top = centerY - 19.5;
              const bottom = centerY + 19.5;
              const ornament = element('g', { 'aria-hidden': 'true' });

              ornament.append(
                element('rect', {
                  x: left,
                  y: top,
                  width,
                  height: 39,
                  rx: 2.6,
                  'stroke-width': 0.85,
                  opacity: 0.92
                }),
                element('rect', {
                  x: left + 2.1,
                  y: top + 2.1,
                  width: Math.max(0, width - 4.2),
                  height: 34.8,
                  rx: 1.7,
                  'stroke-width': 0.42,
                  opacity: 0.58
                }),
                element('path', {
                  d: `M ${left + 4} ${centerY} H ${centerLeft - 7}`,
                  'stroke-width': 0.65,
                  opacity: 0.82
                }),
                element('path', {
                  d: `M ${centerRight + 7} ${centerY} H ${right - 4}`,
                  'stroke-width': 0.65,
                  opacity: 0.82
                }),
                element('path', {
                  d: `M ${centerLeft} ${top + 2} Q ${centerLeft - 8} ${centerY} ${centerLeft} ${bottom - 2}`,
                  'stroke-width': 0.7,
                  opacity: 0.82
                }),
                element('path', {
                  d: `M ${centerRight} ${top + 2} Q ${centerRight + 8} ${centerY} ${centerRight} ${bottom - 2}`,
                  'stroke-width': 0.7,
                  opacity: 0.82
                })
              );

              const motifWidth = Math.max(18, Math.min(42, (width - centerPlateWidth) * 0.13));
              [left + 14, right - 14].forEach((motifCenter, index) => {
                const direction = index === 0 ? 1 : -1;
                const flower = element('g', {
                  transform: `translate(${motifCenter} ${centerY}) scale(${direction} 1)`,
                  opacity: 0.74
                });
                flower.append(
                  element('circle', { cx: 0, cy: 0, r: 2.2, 'stroke-width': 0.55 }),
                  element('path', {
                    d: `M 0 -2.5 C ${motifWidth * 0.20} -12 ${motifWidth * 0.58} -10 ${motifWidth} -4 C ${motifWidth * 0.57} -4 ${motifWidth * 0.32} -1 0 0`,
                    'stroke-width': 0.55
                  }),
                  element('path', {
                    d: `M 0 2.5 C ${motifWidth * 0.20} 12 ${motifWidth * 0.58} 10 ${motifWidth} 4 C ${motifWidth * 0.57} 4 ${motifWidth * 0.32} 1 0 0`,
                    'stroke-width': 0.55
                  }),
                  element('path', {
                    d: `M 4 0 Q ${motifWidth * 0.45} -7 ${motifWidth * 0.78} 0 Q ${motifWidth * 0.45} 7 4 0 Z`,
                    'stroke-width': 0.45
                  })
                );
                ornament.append(flower);
              });

              [left + 47, right - 47].forEach((rosetteCenter, index) => {
                const rosette = element('g', {
                  transform: `translate(${rosetteCenter} ${centerY})`,
                  opacity: 0.68
                });

                for (let petal = 0; petal < 8; petal += 1) {
                  rosette.append(
                    element('ellipse', {
                      cx: 0,
                      cy: -7.2,
                      rx: 2.7,
                      ry: 7.5,
                      transform: `rotate(${petal * 45})`,
                      'stroke-width': 0.44
                    })
                  );
                }

                rosette.append(
                  element('circle', { cx: 0, cy: 0, r: 5.4, 'stroke-width': 0.48 }),
                  element('circle', { cx: 0, cy: 0, r: 1.8, 'stroke-width': 0.5 }),
                  element('path', {
                    d: index === 0
                      ? 'M 10 0 C 18 -10 27 -10 34 -3 C 28 -3 23 0 18 6 C 25 4 30 6 34 10'
                      : 'M -10 0 C -18 -10 -27 -10 -34 -3 C -28 -3 -23 0 -18 6 C -25 4 -30 6 -34 10',
                    'stroke-width': 0.46
                  })
                );
                ornament.append(rosette);
              });

              group.append(ornament);
            });

            const firstArtworkGroup = Array.from(svg.children)
              .find(node => node.localName === 'g');
            if (firstArtworkGroup) {
              svg.insertBefore(group, firstArtworkGroup);
            } else {
              svg.prepend(group);
            }
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

            const originalViewBox = svg.viewBox && svg.viewBox.baseVal
              ? {
                  x: svg.viewBox.baseVal.x,
                  y: svg.viewBox.baseVal.y,
                  width: svg.viewBox.baseVal.width,
                  height: svg.viewBox.baseVal.height
                }
              : null;

            stage.replaceChildren(svg);
            appendSurahOrnaments(svg, payload.surahLines, originalViewBox);
            const fittedViewBox = artworkViewBox(svg, originalViewBox) || originalViewBox;
            if (fittedViewBox) {
              svg.setAttribute(
                'viewBox',
                `${fittedViewBox.x} ${fittedViewBox.y} ${fittedViewBox.width} ${fittedViewBox.height}`
              );
            }

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
