//
//  SearchHistoryCollectionViewCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit
import RxSwift

class SearchHistoryCollectionCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.searchHistoryCollectionCell.identifier
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    private var disposeBag = DisposeBag()
    public var deleteButtonTapAction: () -> Void = {}
    
    
    // MARK: - LifeCycle
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        deleteButton.rx.tap
            .subscribe(with: self, onNext: { strongSelf, _ in
                strongSelf.deleteButtonTapAction()
            })
            .disposed(by: disposeBag)
    }
}
