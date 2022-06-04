//
//  ComicStripViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import Foundation

import RxSwift
import RxCocoa

class ComicStripViewModel {
    private var disposeBag = DisposeBag()
    private var currentEpisode: ComicEpisode
    
    private var watchHistoryHandler = WatchHistoryManager()
    
    public var episodeTitle = BehaviorRelay<String>(value: "")
    public var makeToast = PublishRelay<String>()
    public var comicEpisodes = [EpisodeItem]()

    private var comicStripScenes = [ComicStripScene]()
    public var comicStripScenesObservable = PublishRelay<[ComicStripScene]>()
    public var isLoadingScenes = BehaviorRelay<Bool>(value: false)
    public var failToLoadingScenes = BehaviorRelay<Bool>(value: false)
    
    public var updateRentWatchingEpisode = PublishRelay<String>()
    
    init(currentEpisode: ComicEpisode) {
        self.currentEpisode = currentEpisode
        self.episodeTitle.accept(currentEpisode.title)
    }
}

extension ComicStripViewModel {
    public func renderComicStripScenes(_ episode: EpisodeItem) {
        currentEpisode.replaceEpisode(episode)
        
        episodeTitle.accept(currentEpisode.title)
        comicStripScenesObservable.accept([])
        failToLoadingScenes.accept(false)
        isLoadingScenes.accept(true)
        
        let comicEpisode = ComicEpisode(comicSN: currentEpisode.comicSN,
                                        episodeSN: currentEpisode.episodeSN,
                                        title: currentEpisode.title,
                                        description: currentEpisode.description,
                                        thumbnailImagePath: currentEpisode.thumbnailImagePath)
        
        MarumaruApiService.shared.getComicStripScenes(comicEpisode)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, scenes in
                strongSelf.isLoadingScenes.accept(false)
                strongSelf.comicStripScenes = scenes
                strongSelf.comicStripScenesObservable.accept(scenes)
                strongSelf.updateComicEpisodes()
                strongSelf.currentEpisode.thumbnailImagePath = scenes.first?.imagePath
            }, onFailure: { strongSelf, _ in
                strongSelf.comicStripScenesObservable.accept([])
                strongSelf.failToLoadingScenes.accept(true)
                strongSelf.isLoadingScenes.accept(false)
            }).disposed(by: self.disposeBag)
    }
    
    public func renderCurrentEpisodeScenes() {
        let currentEpisode = EpisodeItem(title: currentEpisode.title,
                                         episodeSN: currentEpisode.episodeSN)
        renderComicStripScenes(currentEpisode)
    }
    
    public func renderNextEpisodeScenes() {
        guard let currentEpisodeIndex = currentEpisodeIndex else {
            return
        }
        
        let targetIndex = currentEpisodeIndex + 1
        if comicEpisodes.isInBound(targetIndex) {
            let nextEpisode = comicEpisodes[targetIndex]
            renderComicStripScenes(nextEpisode)
        } else {
            makeToast.accept("message.lastEpisode".localized())
        }
    }
    
    public func renderPreviousEpisodeScenes() {
        guard let currentEpisodeIndex = currentEpisodeIndex else {
            return
        }

        let targetIndex = currentEpisodeIndex - 1
        if comicEpisodes.isInBound(targetIndex) {
            let previousEpisode = comicEpisodes[targetIndex]
            renderComicStripScenes(previousEpisode)
        } else {
            makeToast.accept("message.firstEpisode".localized())
        }
    }
    
    public var currentEpisodeIndex: Int? {
        for (i, episode) in comicEpisodes.enumerated()
        where episode.episodeSN == currentEpisode.episodeSN {
            return i
        }
        
        return nil
    }
}

extension ComicStripViewModel {
    private var firstSceneImageUrl: String? {
        return comicStripScenes.first?.imagePath
    }
    
    public func saveToWatchHistory() {
        let currentEpisode = currentEpisode
        
        watchHistoryHandler
            .addData(currentEpisode)
            .subscribe(with: self, onCompleted: { strongSelf in
                strongSelf.updateRentWatchingEpisode.accept(currentEpisode.episodeSN)
            })
            .disposed(by: disposeBag)
    }
}

extension ComicStripViewModel {
    private func updateComicEpisodes() {
        MarumaruApiService.shared.getEpisodesInStrip(currentEpisode)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, episodes in
                strongSelf.comicEpisodes = episodes.reversed()
            }).disposed(by: self.disposeBag)
    }
}

extension ComicStripViewModel {
    public var serialNumber: String {
        return currentEpisode.episodeSN
    }
}
