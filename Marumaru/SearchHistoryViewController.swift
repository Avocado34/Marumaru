//
//  SearchHistoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit
import RxDataSources

protocol SearchHistoryViewDelegate: AnyObject {
    func didSelectedSearchHistory(title: String)
    func didHistoryCollectionViewViewScrolled()
}

class SearchHistoryViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = SearchHistoryViewModel
    static let identifier = R.storyboard.searchHistory.searchHistoryStoryboard.identifier
    
    @IBOutlet weak var searchHistoryCollectionView: UICollectionView!
    
    weak var delegate: SearchHistoryViewDelegate?
    var viewModel: SearchHistoryViewModel
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SearchHistorySection>?
    private var searchResultCollectionViewTopInset: CGFloat {
        return regularAppbarHeight
    }
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        self.dataSource = dataSourceFactory()
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
    
    // MARK: - Setups

    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.updateSearchHistory()
    }
    
    private func setupView() {
        setupSearchHistoryCollectionView()
    }
    
    private func setupSearchHistoryCollectionView() {
        registerSearchHistoryCell()
        registerSearchHistoryHeader()
        registerSearchHistoryFooter()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 20
        flowLayout.itemSize = CGSize(width: view.frame.width, height: 36)
        flowLayout.headerReferenceSize = CGSize(width: view.frame.width, height: 100)
        flowLayout.footerReferenceSize = CGSize(width: view.frame.width, height: 100)
        searchHistoryCollectionView.collectionViewLayout = flowLayout
        
        searchHistoryCollectionView.clipsToBounds = false
        searchHistoryCollectionView.alwaysBounceVertical = true
        configureSearchHistoryCollectionViewInsets()
    }
    
    private func registerSearchHistoryCell() {
        let nibName = UINib(nibName: SearchHistoryCollectionCell.identifier, bundle: nil)
        searchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: SearchHistoryCollectionCell.identifier)
    }
    
    private func registerSearchHistoryHeader() {
        let nibName = UINib(nibName: R.nib.descriptionHeaderReusableView.name,
                            bundle: nil)
        searchHistoryCollectionView.register(nibName,
                                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                             withReuseIdentifier: DescriptionHeaderReusableView.identifier)
    }
    
    private func registerSearchHistoryFooter() {
        let nibName = UINib(nibName: R.nib.singleButtonFooterReusableView.name,
                            bundle: nil)
        searchHistoryCollectionView.register(nibName,
                                             forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                             withReuseIdentifier: SingleButtonFooterReusableView.identifier)
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureSearchHistoryCollectionViewInsets()
    }
    
    private func configureSearchHistoryCollectionViewInsets() {
        searchHistoryCollectionView.contentInset = UIEdgeInsets(top: searchResultCollectionViewTopInset,
                                                               left: 0, bottom: 40, right: 0)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchHistoryCollectionView()
        bindSearchHistoryCollectionCell()
        bindCollectionViewScrollAction()
    }
    
    private func bindSearchHistoryCollectionView() {
        guard let dataSource = dataSource else {
            return
        }

        viewModel.searchHistoriesObservable
            .bind(to: searchHistoryCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func bindSearchHistoryCollectionCell() {
        searchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.selectHistoryItem(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.didSelectedHistoryItem
            .subscribe(with: self, onNext: { vc, searchHistory in
                vc.delegate?.didSelectedSearchHistory(title: searchHistory.title)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCollectionViewScrollAction() {
        searchHistoryCollectionView.rx.didScroll
            .subscribe(with: self, onNext: { vc, _ in
                vc.view.endEditing(true)
                vc.delegate?.didHistoryCollectionViewViewScrolled()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func dataSourceFactory() -> RxCollectionViewSectionedReloadDataSource<SearchHistorySection> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<SearchHistorySection>(configureCell: { _, cv, indexPath, historyItem in
            guard let cell = cv.dequeueReusableCell(withReuseIdentifier: SearchHistoryCollectionCell.identifier, for: indexPath) as? SearchHistoryCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.titleLabel.text = historyItem.title
            cell.deleteButtonTapAction = { [weak self] in
                self?.viewModel.deleteSearchHistoryItem(indexPath.row)
            }
            
            return cell
        }, configureSupplementaryView: { [weak self] _, cv, kind, indexPath in
            guard let self = self else { return UICollectionReusableView() }
            
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                guard let headerView = cv.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DescriptionHeaderReusableView.identifier, for: indexPath) as? DescriptionHeaderReusableView else {
                    return UICollectionReusableView()
                }
                
                if self.viewModel.searchHistories.isEmpty {
                    headerView.descriptionLabel.text = "message.noSearchHistory".localized()
                } else {
                    headerView.descriptionLabel.text = "title.searchHistory".localized()
                }
                
                return headerView
            case UICollectionView.elementKindSectionFooter:
                guard let footerView = cv.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SingleButtonFooterReusableView.identifier, for: indexPath) as? SingleButtonFooterReusableView else {
                    return UICollectionReusableView()
                }
                
                if self.viewModel.searchHistories.isEmpty {
                    footerView.mainButton.isHidden = true
                } else {
                    footerView.mainButton.isHidden = false
                    footerView.mainButton.setTitle("title.deleteAll".localized(), for: .normal)
                    footerView.mainButton.titleLabel?.makeUnderLine()
                }

                footerView.mainButtonTapAction = { [weak self] in
                    self?.viewModel.deleteAllSearchHistory()
                }
                
                return footerView
            default:
                return UICollectionReusableView()
            }
        })
            
        return dataSource
    }
}
