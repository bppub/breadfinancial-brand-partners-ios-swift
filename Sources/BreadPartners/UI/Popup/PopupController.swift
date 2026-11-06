//------------------------------------------------------------------------------
//  File:          PopupController.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import UIKit
import WebKit

/// A view controller responsible for presenting and coordinating popup content.
@MainActor
internal final class PopupController: UIViewController {
    let input: PopupInput
    let logger: Logger
    let callback: (BreadPartnerEvents) -> Void

    private(set) var popupView: PopupChromeView!
    private(set) var productView: PopupProductView?
    private(set) var embeddedView: PopupEmbeddedView?
    private(set) var loadingView: PopupLoadingView?
    private(set) var setupTask: Task<Void, Never>?
    var webViewContent: PopupInput.Embedded?

    private lazy var webViewCoordinator = PopupWebViewCoordinator(
        logger: logger,
        onEvent: { [weak self] event in self?.handleWebViewEvent(event: event) },
        onPageLoadCompleted: { [weak self] in self?.loadingView?.stopAnimating() }
    )

    init(
        input: PopupInput,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        self.input = input
        self.logger = logger
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTask = Task { [weak self] in
            await self?.setupUI()
        }
    }

    private func setupUI() async {
        setupPopupChrome()

        switch input.content {
        case .embedded(let content):
            await setupEmbeddedOverlay(content: content)

        case .product(let content):
            setupProductOverlay(content: content)

            guard let loadActionContent = content.loadActionContent
            else { return }

            do {
                webViewContent = try await loadActionContent(content.actionPlacementID)
            } catch {
                return
            }
        }
    }

    @objc func closeButtonTapped() {
        callback(.popupClosed)

        dismiss(animated: true)
    }

    func actionButtonTapped() {
        callback(.actionButtonTapped)

        guard let webViewContent else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.somethingWentWrong]
                    )
                )
            )
            return
        }

        productView?.isHidden = true
        guard let url = webViewURL(for: webViewContent) else { return }
        setupLoadingView().startAnimating()
        _ = prepareEmbeddedOverlay(content: webViewContent, url: url)
    }

    func handleWebViewEvent(event: BreadPartnerEvents) {
        if case .popupClosed = event {
            closeButtonTapped()
        } else {
            callback(event)
        }
    }

    private func setupPopupChrome() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        popupView = PopupChromeView(
            style: input.style,
            configuration: input.chromeConfiguration,
            onClose: { [weak self] in self?.closeButtonTapped() }
        )

        popupView.install(in: view)
    }

    private func setupProductOverlay(content: PopupInput.Product) {
        let productView = PopupProductView(
            presentation: PopupProductPresentationMapper().map(product: content, style: input.style),
            onAction: { [weak self] in self?.actionButtonTapped() }
        )
        self.productView = productView
        popupView.addSubview(productView)

        NSLayoutConstraint.activate([
            productView.topAnchor.constraint(equalTo: popupView.contentTopAnchor),
            productView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
            productView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
            productView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor),
        ])
    }

    private func setupEmbeddedOverlay(content: PopupInput.Embedded) async {
        guard let url = webViewURL(for: content) else { return }

        let loadingView = setupLoadingView()
        loadingView.startAnimating()

        let webView = prepareEmbeddedOverlay(content: content, url: url)
        do {
            let loadedURL = try await webViewCoordinator.loadPage(for: webView)
            logger.printLog("Loaded URL: \(loadedURL)")
        } catch {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.apiError(message: error.localizedDescription)]
                    )
                )
            )
        }

        loadingView.stopAnimating()
    }

    private func webViewURL(for content: PopupInput.Embedded) -> URL? {
        guard let url = URL(string: content.webViewURL) else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.unableToLoadWebURL(message: content.webViewURL)]
                    )
                )
            )
            return nil
        }
        return url
    }

    private func prepareEmbeddedOverlay(content: PopupInput.Embedded, url: URL) -> WKWebView {
        productView?.isHidden = true
        let embeddedView = self.embeddedView ?? PopupEmbeddedView()
        self.embeddedView = embeddedView
        if embeddedView.superview == nil {
            popupView.addSubview(embeddedView)
            NSLayoutConstraint.activate([
                embeddedView.topAnchor.constraint(equalTo: popupView.contentTopAnchor),
                embeddedView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
                embeddedView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
                embeddedView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor),
            ])
        }

        let webView = webViewCoordinator.installWebView(with: url, in: embeddedView)

        popupView.loadLogo(from: content.logoURL)
        return webView
    }

    private func setupLoadingView() -> PopupLoadingView {
        if let loadingView {
            return loadingView
        }

        let loadingView = PopupLoadingView(color: input.style.loaderColor)
        self.loadingView = loadingView
        loadingView.install(in: popupView)
        return loadingView
    }
}
