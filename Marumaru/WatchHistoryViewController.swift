//
//  WatchHistoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources
import FloatingPanel

class WatchHistoryViewController: BaseViewController, ViewModelInjectable {
        
    
    // MARK: - Properties
    
    typealias ViewModel = WatchHistoryViewModel
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    
    static let identifier = R.storyboard.watchHistory.watchHistoryStoryboard.identifier
    var viewModel: ViewModel
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection>?
    private var fpc = FloatingPanelController()
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: WatchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        dataSource = dataSourceFactory()
    }
    
    required init?(coder: NSCoder) {
        fatalError("ViewModel has not been implemented")
    }
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        viewModel.updateWatchHistories()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupWatchHistoryCollectionView()
        setupClearHistoryButton()
        setupFloatingPanelView()
    }
    
    private func setupWatchHistoryCollectionView() {
        registerWatchHistoryCollectionCell()
        registerWatchHistoryHeader()
        registerWatchHistoryFooter()
        
        watchHistoryCollectionView.collectionViewLayout = flowLayout()
        watchHistoryCollectionView.contentInset = UIEdgeInsets.top(compactAppbarHeight + view.safeAreaInsets.top + 24)
    }
    
    private func registerWatchHistoryCollectionCell() {
        let nibName = UINib(nibName: ComicEpisodeThumbnailCollectionCell.identifier, bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
    }
    
    private func registerWatchHistoryHeader() {
        watchHistoryCollectionView.register(WatchHistoryCollectionReusableView.self,
                                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                            withReuseIdentifier: WatchHistoryCollectionReusableView.identifier)
    }
    
    private func registerWatchHistoryFooter() {
        watchHistoryCollectionView.register(WatchHistoryCollectionReusableView.self,
                                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                            withReuseIdentifier: WatchHistoryCollectionReusableView.identifier)
    }
    
    private func setupClearHistoryButton() {
        clearHistoryButton.layer.masksToBounds = true
        clearHistoryButton.layer.cornerRadius = 8
    }
    
    private func setupFloatingPanelView() {
        fpc.layout = ShowComicOptionFloatingPanelLayout()
        
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 16
        fpc.surfaceView.appearance = appearance
        
        fpc.surfaceView.backgroundColor = R.color.backgroundWhite()
        fpc.surfaceView.grabberHandle.isHidden = true
        
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.isRemovalInteractionEnabled = true
    }
    
    
    // MARK: - Configurations
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
    }
    
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + compactAppbarHeight
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindClearHistoryButton()
        bindWatchHistoryCollectionView()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .debug()
            .drive(with: self, onNext: { vc, _  in
                vc.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindClearHistoryButton() {
        clearHistoryButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.presentClearHistoryActionSheet()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCollectionView() {
        watchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.comicItemSelected(indexPath)
            }).disposed(by: disposeBag)
        
        viewModel.presentComicDetailVC
            .subscribe(with: self, onNext: { vc, comicEpisode in
                vc.presentShowComicOptionAlertFPC(comicEpisode)
            })
            .disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .bind(to: watchHistoryCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
                    vc.view.makeNoticeLabel("message.emptyWatchHistory".localized())
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func dataSourceFactory() -> RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection> {
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<WatchHistorySection>(configureCell: { [weak self] _, cv, indexPath, comicEpisode in
            if comicEpisode.isInvalidated { return UICollectionViewCell() }
            
            guard let self = self,
                  let cell = cv.dequeueReusableCell(withReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier, for: indexPath)
                    as? ComicEpisodeThumbnailCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.titleLabel.text = comicEpisode.title
            cell.thumbnailImagePlaceholderLabel.text = comicEpisode.title
            
            let url = self.viewModel.getImageURL(comicEpisode.thumbnailImagePath)
            cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                do {
                    let result = try result.get()
                    let image = result.image
                    cell.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
                    cell.thumbnailImagePlaceholderLabel.isHidden = true
                } catch {
                    cell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
             
            return cell
        }, configureSupplementaryView: { [weak self] _, cv, _, indexPath in
            guard let self = self else { return .init() }
            
            guard let headerView = cv.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WatchHistoryCollectionReusableView.identifier, for: indexPath) as? WatchHistoryCollectionReusableView else {
                return UICollectionReusableView()
            }

            headerView.dateLabel.text = self.viewModel.sectionHeader(indexPath)
            return headerView
        })
        
        return dataSource
    }
    
    private func presentClearHistoryActionSheet() {
        let deleteMenu = UIAlertController(title: "title.removeHistory".localized(),
                                           message: "message.removeHistory".localized(),
                                           preferredStyle: .actionSheet)
        
        let clearAction = UIAlertAction(title: "title.remove".localized(), style: .destructive) { [weak self] _ in
            self?.viewModel.clearHistories()
        }
        let cancelAction = UIAlertAction(title: "title.cancel".localized(), style: .cancel)
        
        deleteMenu.addAction(clearAction)
        deleteMenu.addAction(cancelAction)
        deleteMenu.popoverPresentationController?.sourceView = clearHistoryButton!
        deleteMenu.popoverPresentationController?.sourceRect = (clearHistoryButton as AnyObject).bounds
        
        self.present(deleteMenu, animated: true)
    }
    
    private func presentShowComicOptionAlertFPC(_ comicEpisode: ComicEpisode) {
        let storyboard = UIStoryboard(name: R.storyboard.showComicOption.name, bundle: nil)
        let comicDetailVC = storyboard.instantiateViewController(identifier: ShowComicOptionAlertViewController.identifier,
                                                                creator: { coder -> ShowComicOptionAlertViewController in
            let viewModel = ShowComicOptionAlertViewModel(currentEpisode: comicEpisode)
            return .init(coder, viewModel) ?? ShowComicOptionAlertViewController(viewModel)
        })
        
        comicDetailVC.delegate = self
        fpc.set(contentViewController: comicDetailVC)
        
        makeImpactFeedback(.light)
        self.present(fpc, animated: true)
    }
    
    private func presentComicStripVC(_ comicEpisode: ComicEpisode) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let viewModel = ComicStripViewModel(currentEpisode: comicEpisode)

            return .init(coder, viewModel) ?? ComicStripViewController(viewModel)
        })

        comicStripVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(comicStripVC, animated: true)
    }
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storybaord = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let comicStripVC = storybaord.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                                creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel(comicInfo: comicInfo)
            return .init(coder, viewModel) ?? ComicDetailViewController(viewModel)
        })
        
        present(comicStripVC, animated: true)
    }
}


// MARK: - Extensions

extension WatchHistoryViewController {
    private func flowLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(136),
                heightDimension: .absolute(236))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(136),
                heightDimension: .absolute(236))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
            group.interItemSpacing = .fixed(12)
            
            let supplymentaryItemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(environment.container.contentSize.width),
                heightDimension: .absolute(44))
            let supplymentaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplymentaryItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topLeading)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.boundarySupplementaryItems = [supplymentaryItem]
            section.interGroupSpacing = 4
            
            return section
        }
        
        return layout
    }
}

extension WatchHistoryViewController: ShowComicOptionAlertViewDelegate {
    func didTapShowComicStripButton(_ comicEpisode: ComicEpisode) {
        presentComicStripVC(comicEpisode)
    }
    
    func didTapShowComicDetailButton(_ comicInfo: ComicInfo) {
        presentComicDetailVC(comicInfo)
    }
}
