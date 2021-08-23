//
//  EpisodePopoverViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

// MARK: Protocol
protocol SelectItemDelegate: AnyObject {
    func loadSelectedEpisode(_ episode: Episode)
}

class EpisodePopoverViewController: UIViewController {
    
    // MARK: - Declarations
    weak var selectItemDelegate: SelectItemDelegate?
    
    var episodeArr = [Episode]()
    var currentEpisode: Episode?
    var currentEpisodeIndex: Int?
    
    @IBOutlet weak var episodePopoverTableView: UITableView!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initData()
        initView()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setEpisodeTableView(index: currentEpisodeIndex)
    }
    
    // MARK: Initializations
    func initData() {
        if currentEpisode == nil {
            popoverPresentationController?.dismissalTransitionDidEnd(true)
            return
        }
    }
    
    func initView() {
        episodePopoverTableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        episodePopoverTableView.tableFooterView = UIView()
    }
    
    func initInstance() {
        episodePopoverTableView.delegate = self
        episodePopoverTableView.dataSource = self
    }
    
    func setEpisodeTableView(index: Int?) {
        if let index = index {
            let indexPath = IndexPath(row: index, section: 0)
            episodePopoverTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
}

// MARK: - Extensions
extension EpisodePopoverViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return episodeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: "popoverEpisodeCell") as? MangaEpisodePopoverCell else { return UITableViewCell() }
        
        if episodeArr.count <= indexPath.row {
            return UITableViewCell()
        }
        
        episodeCell.episodeTitleLabel.text = episodeArr[indexPath.row].title
        
        // Accent text color to current episode
        if episodeArr[indexPath.row].serialNumber == currentEpisode!.serialNumber {
            episodeCell.episodeTitleLabel.textColor = ColorSet.accentColor
            episodeCell.contentView.backgroundColor = ColorSet.cellSelectionColor
        } else {
            episodeCell.episodeTitleLabel.textColor = ColorSet.textColor
            episodeCell.contentView.backgroundColor = ColorSet.transparentColor
        }
        
        return episodeCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if episodeArr.count > indexPath.row {
            selectItemDelegate?.loadSelectedEpisode(episodeArr[indexPath.row])
            dismiss(animated: true, completion: nil)
        }
    }
    
}
