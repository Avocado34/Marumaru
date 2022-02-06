//
//  ViewMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import SwiftSoup
import Lottie
import Toast
import Hero
import RxSwift
import RxCocoa
import RxGesture

@objc protocol PlayMangaViewDelegate: AnyObject {
    @objc optional func didWatchHistoryUpdated()
}

class PlayMangaViewController: UIViewController {
    
    // MARK: - Declarations
    @IBOutlet weak var showEpisodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    public weak var delegate: PlayMangaViewDelegate?
    private var viewModel: PlayMangaViewModel
    private var disposeBag = DisposeBag()
    
    private var cellHeightDictionary: NSMutableDictionary = [:]
    private let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
    private var isSceneZoomed = false
    
    private var sceneLoadingAnimationView = LottieAnimationView()
    private var sceneScrollView = FlexibleSceneScrollView()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        bind()
        playManga()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.didWatchHistoryUpdated?()
    }
    
    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializers
    init?(
        coder: NSCoder,
        viewModel: PlayMangaViewModel
    ) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setup() {
        setupView()
    }
    
    // MARK: - SetupView
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupSceneScrollView()
        setupAppbarView()
        setupBackButton()
        setupBottomIndicatorView()
        setupPreviousEpisodeButton()
        setupShowEpisodeListButton()
        setupNextEpisodeButton()
        setupMangaTitleLabel()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupSceneScrollView() {
        sceneScrollView = FlexibleSceneScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        sceneScrollView.minimumZoomScale = 1
        sceneScrollView.maximumZoomScale = 3
        sceneScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomIndicatorView.frame.height, right: 0)
        view.insertSubview(sceneScrollView, at: 0)
        sceneScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sceneScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sceneScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sceneScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sceneScrollView.delegate = self
        
        viewModel.reloadSceneScrollView = { [weak self] in
            guard let self = self else { return }
            self.sceneScrollView.sceneArr = self.viewModel.currentEpisodeScenes
            self.sceneScrollView.reloadData()
        }
        
        viewModel.prepareForReloadSceneScrollview = { [weak self] in
            self?.playSceneLoadingAnimation()
            self?.disableIndicatorButtons()
            self?.sceneScrollView.clearAndReloadData()
        }
    }
    
    private func setupAppbarView() {
        appbarView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        appbarView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        appbarView.layer.cornerRadius = 24
        appbarView.layer.maskedCorners = CACornerMask([.layerMinXMaxYCorner])
        appbarView.hero.modifiers = [.translate(y: -appbarView.frame.height)]
    }
    
    private func setupBackButton() {
        backButton.layer.cornerRadius = 12
        backButton.imageEdgeInsets(with: 10)
    }
    
    private func setupBottomIndicatorView() {
        bottomIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomIndicatorView.hero.modifiers = [.translate(y: bottomIndicatorView.frame.height)]
    }
    
    private func setupNextEpisodeButton() {
        nextEpisodeButton.layer.cornerRadius = 10
        nextEpisodeButton.imageEdgeInsets(with: 8)
    }
    
    private func setupPreviousEpisodeButton() {
        previousEpisodeButton.layer.cornerRadius = 10
        previousEpisodeButton.imageEdgeInsets(with: 8)
    }
    
    private func setupShowEpisodeListButton() {
        showEpisodeListButton.layer.cornerRadius = 10
        showEpisodeListButton.imageEdgeInsets(with: 8)
    }
    
    private func setupMangaTitleLabel() {
        mangaTitleLabel.text = viewModel.currentEpisodeTitle
        
        viewModel.updateMangaTitleLabel = { [weak self] in
            self?.mangaTitleLabel.text = self?.viewModel.currentEpisodeTitle
        }
    }
    
    // MARK: - Bind
    private func bind() {
        bindBackButton()
        bindNextEpisodeButton()
        bindPreviousEpisodeButton()
        bindShowEpisodeListButton()
        bindSceneSingleTapGesture()
        bindSceneDoubleTapGesture()
        bindSceneScrollView()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNextEpisodeButton() {
        nextEpisodeButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.playNextManga()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindPreviousEpisodeButton() {
        previousEpisodeButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.playPreviousManga()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindShowEpisodeListButton() {
        showEpisodeListButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.presentEpisodePopoverVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneSingleTapGesture() {
        let sceneTapGestureRocognizer = UITapGestureRecognizer()
        sceneTapGestureRocognizer.numberOfTapsRequired = 1
//        sceneTapGestureRocognizer.require(toFail: sceneDoubleTapGestureRecognizer)
        sceneScrollView.rx
            .gesture(sceneTapGestureRocognizer)
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                if self?.appbarView.alpha == 0 {
                    self?.showNavigationBar()
                } else {
                    self?.hideNavigationBar()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneDoubleTapGesture() {
        let sceneDoubleTapGestureRecognizer = UITapGestureRecognizer()
        sceneDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        sceneScrollView.addGestureRecognizer(sceneDoubleTapGestureRecognizer)
        sceneScrollView.rx
            .gesture(sceneDoubleTapGestureRecognizer)
            .when(.recognized)
            .subscribe(onNext: { [weak self] recognizer in
                let tapPoint = recognizer.location(in: self?.sceneScrollView.contentView)
                self?.zoom(point: tapPoint)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSceneScrollView() {
        sceneScrollView.rx.contentOffset
            .subscribe(onNext: { [weak self] offset in
                guard let self = self else { return }
                
                let overPanThreshold: CGFloat = 50
                // reached the top
                if offset.y < -(overPanThreshold + overPanThreshold) {
                    self.showNavigationBar()
                }
                
                // reached the bottom
                if offset.y > self.sceneScrollView.contentSize.height - self.view.frame.height + overPanThreshold + self.bottomIndicatorView.frame.height {
                    self.showNavigationBar()
                }
            })
            .disposed(by: disposeBag)
        
        sceneScrollView.rx.panGesture()
            .when(.began)
            .subscribe(onNext: { [weak self] _ in
                self?.hideNavigationBar()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Methods
    private func playManga() {
        viewModel.playCurrentManga()
            .subscribe(onCompleted: { [weak self] in
                self?.sceneLoadingAnimationView.stop()
                self?.enableIndicatorButtons()
            }).disposed(by: disposeBag)
    }
    
    private func playManga(serialNumber: String) {
        viewModel.playManga(serialNumber)
            .subscribe(onCompleted: { [weak self] in
                self?.sceneLoadingAnimationView.stop()
                self?.enableIndicatorButtons()
            }).disposed(by: disposeBag)
    }
    
    private func presentEpisodePopoverVC() {
        let viewModel = EpisodePopOverViewModel(viewModel.getSerialNumberFromUrl(), viewModel.currentMangaEpisoeds)
        
        guard let episodePopoverVC = storyboard?.instantiateViewController(identifier: "EpisodePopoverStoryboard", creator: { coder in
            EpisodePopOverViewController(coder: coder, viewModel: viewModel)
        }) else { return }

        episodePopoverVC.modalPresentationStyle = .popover
        episodePopoverVC.preferredContentSize = CGSize(width: 200, height: 300)
        episodePopoverVC.popoverPresentationController?.permittedArrowDirections = .down
        episodePopoverVC.popoverPresentationController?.sourceRect = showEpisodeListButton.bounds
        episodePopoverVC.popoverPresentationController?.sourceView = showEpisodeListButton
        episodePopoverVC.presentationController?.delegate = self
        episodePopoverVC.delegate = self
        
        present(episodePopoverVC, animated: true, completion: nil)
    }
}

extension PlayMangaViewController {
    private func playSceneLoadingAnimation() {
        sceneLoadingAnimationView.play(name: "loading_cat",
                                       size: CGSize(width: 148, height: 148),
                                       to: view)
    }
}

extension PlayMangaViewController {
    func playNextManga() {
        viewModel.playNextManga()
            .subscribe(onCompleted: { [weak self] in
                self?.sceneLoadingAnimationView.stop()
                self?.enableIndicatorButtons()
            }, onError: { [weak self] error in
                if let error = error as? PlayMangaViewError {
                    self?.view.makeToast(error.message)
                }
            }).disposed(by: disposeBag)
    }
    
    func playPreviousManga() {
        viewModel.playPreviousManga()
            .subscribe(onCompleted: { [weak self] in
                self?.sceneLoadingAnimationView.stop()
                self?.enableIndicatorButtons()
            }, onError: { [weak self] error in
                if let error = error as? PlayMangaViewError {
                    self?.view.makeToast(error.message)
                }
            }).disposed(by: disposeBag)
    }
}

extension PlayMangaViewController {
    func zoom(point: CGPoint) {
        if isSceneZoomed {
            // zoom out
            sceneScrollView.zoom(to: CGRect(x: point.x, y: point.y, width: self.view.frame.width, height: self.view.frame.height), animated: true)
            isSceneZoomed = false
        } else {
            // zoom in
            hideNavigationBar()
            sceneScrollView.zoom(to: CGRect(x: point.x, y: point.y, width: self.view.frame.width / 2, height: self.view.frame.height / 2), animated: true)
            isSceneZoomed = true
        }
    }
}

extension PlayMangaViewController {
    private func enableIndicatorButtons() {
        toggleIndicatorButtons(true)
    }
    
    private func disableIndicatorButtons() {
        toggleIndicatorButtons(false)
    }
    
    private func toggleIndicatorButtons(_ state: Bool) {
        previousEpisodeButton.isEnabled = state
        showEpisodeListButton.isEnabled = state
        nextEpisodeButton.isEnabled = state
    }
}

extension PlayMangaViewController {
    func showNavigationBar() {
        if appbarView.alpha == 0 {
            appbarView.startFadeInAnimation(duration: 0.3)
            bottomIndicatorView.startFadeInAnimation(duration: 0.3)
        }
    }
    
    func hideNavigationBar() {
        if appbarView.alpha == 1 {
            appbarView.startFadeOutAnimation(duration: 0.3)
            bottomIndicatorView.startFadeOutAnimation(duration: 0.3)
        }
    }
}

extension PlayMangaViewController: UIScrollViewDelegate {
    // Set scene scrollview zoomable
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.sceneScrollView.contentView
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension PlayMangaViewController: EpisodePopOverViewDelegate {
    func didEpisodeSelected(_ serialNumber: String) {
        playManga(serialNumber: serialNumber)
    }
}