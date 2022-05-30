//
//  SearchHistoryManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import Foundation

import RealmSwift
import RxSwift

class SearchHistoryManager {
    
    func addData(_ object: SearchHistory) -> Completable {
        return Completable.create { observer  in
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    realmInstance.add(object, update: .modified)
                }
                
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData() -> Single<[SearchHistory]> {
        return Single.create { observer in
            do {
                let realmInstance = try Realm()
                let searchHistories = Array(realmInstance.objects(SearchHistory.self))
                observer(.success(searchHistories))
            } catch {
                observer(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteData(_ object: SearchHistory) -> Completable {
        return Completable.create { observer  in
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    realmInstance.delete(object)
                }
                
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteAll() -> Completable {
        return Completable.create { observer  in
            do {
                let realmInstance = try Realm()
                realmInstance.deleteAll()
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
}
