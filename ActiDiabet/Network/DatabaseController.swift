//
//  DatabaseController.swift
//  ActiDiabet
//
//  Created by 佟诗博 on 22/4/20.
//  Copyright © 2020 Shibo Tong. All rights reserved.
//

import Foundation

enum ListenerType {
    case all
    case recommend
    case map
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func getActivities(activities: [Activity])
    func addLocation(place: [OpenSpaces])
}

protocol DatabaseProtocol: AnyObject {
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    func addUser(intensity: String, postcode: String)
    func addReview(userid: String, activity: Activity, rate: Int)
    func searchActivity(str: String)
    func fetchAllActivities()
}

let link = "http://ieserver-env.eba-kpxgxhpr.ap-southeast-2.elasticbeanstalk.com/"

class DatabaseController: NSObject {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    
    var favouriteController = FavouriteController()
    
    var activities: [Activity]
    
    var recommendActivities: [Activity]
    
    var places: [OpenSpaces]
    
    override init() {
        self.activities = []
        self.recommendActivities = []
        self.places = []
        super.init()
        self.fetchRecommendActivity()
        
        
    }
    
    // MARK: performing data return jsonArray
    private func performData(_ data: Data) -> [[String: Any]]? {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard json != nil else { return nil }
        guard let dictionary = json as? [String: Any] else { return nil }
        guard let jsonArray = dictionary["result"] as? [[String: Any]]else { return nil }
        return jsonArray
    }
    
    
    
    private func performUserID(_ data: Data) {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard json != nil else { return }
        guard let dictionary = json as? [String: Any] else { return }
        guard let userid = dictionary["result"] as? String else { return }
        print("create account success, userid: \(userid)")
        UserDefaults.standard.set(userid, forKey: "userid")
    }
    

}

extension DatabaseController: DatabaseProtocol {
    //MARK: -Fetch all activities
    func fetchAllActivities() {
        let url = URL(string: link + "activity")
        if let url = url {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    self.activities = []
                    if let jsonArray = self.performData(data) {
                        for item in jsonArray {
                            guard let activity = Activity(json: item) else {
                                print("activity init failed \(item)")
                                return
                            }
                            activity.like = self.favouriteController.findUserLike(activity: activity)
                            self.activities.append(activity)
                        }
                        self.fetchOpenSpaces()
                        self.listeners.invoke { (listener) in
                            if listener.listenerType == .all {
                                listener.getActivities(activities: self.activities)
                            }
                        }
                    }
                    
                }
            }.resume()
        }
    }
    
    //MARK: -Fetch Recommend Activities
    func fetchRecommendActivity() {
        let url = URL(string: link + "activity/recommendation/1")
        if let url = url {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    self.recommendActivities = []
                    if let jsonArray = self.performData(data) {
                        for item in jsonArray {
                            guard let activity = Activity(json: item) else {
                                print("activity init failed \(item)")
                                return
                            }
                            activity.like = self.favouriteController.findUserLike(activity: activity)
                            self.activities.append(activity)
                        }
                        self.fetchAllActivities()
                        self.listeners.invoke { (listener) in
                            if listener.listenerType == .recommend {
                                listener.getActivities(activities: self.recommendActivities)
                                
                            }
                        }
                    }
                }
            }.resume()
        }
    }
    
    func searchActivity(str: String) {
        let url = URL(string: link + "activity/search/byString/\(str)")
        if let url = url {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    self.activities = []
                    if let jsonArray = self.performData(data) {
                        for item in jsonArray {
                            guard let activity = Activity(json: item) else {
                                print("activity init failed \(item)")
                                return
                            }
                            activity.like = self.favouriteController.findUserLike(activity: activity)
                            self.activities.append(activity)
                        }
                        self.listeners.invoke { (listener) in
                            if listener.listenerType == .all {
                                listener.getActivities(activities: self.activities)
                            }
                        }
                    }
                }
            }.resume()
        }
    }
    
    //MARK: -Fetch All openspaces
    func fetchOpenSpaces() {
        let zip = UserDefaults.standard.object(forKey: "zipcode") as? String
        if zip == nil {
            
        } else {
            
            let placeUrl = URL(string: link + "activity/place/\(zip!)")
            print(placeUrl?.absoluteString)
            if let url = placeUrl {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        print(error)
                    }
                    if let data = data {
                        print("open space data \(data)")
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        guard json != nil else { return }
                        guard let dictionary = json as? [String: Any] else { return }
                        guard let jsonArray = dictionary["result"] as? [[String: Any]]else { return }
                        jsonArray.forEach { (item) in
                            guard let location = OpenSpaces(json: item, type: .space) else { return }
                            self.places.append(location)
                            //self.fetchPools()
                        }
                    }
                }.resume()
            }
        }
        
    }
    
    func fetchPools() {
        let zip = UserDefaults.standard.object(forKey: "zipcode") as! String
        let poolUrl = URL(string: link + "activity/pool/\(zip)")
        if let url = poolUrl {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    guard json != nil else { return }
                    guard let dictionary = json as? [String: Any] else { return }
                    guard let jsonArray = dictionary["result"] as? [[String: Any]]else { return }
                    jsonArray.forEach { (item) in
                        guard let location = OpenSpaces(json: item, type: .pool) else { return }
                        self.places.append(location)
                    }
                    self.listeners.invoke { (listener) in
                        if listener.listenerType == .map {
                            listener.addLocation(place: self.places)
                        }
                    }
                    
                }
            }.resume()
        }
    }
    
    //MARK: -add user in database
    func addUser(intensity: String, postcode: String) {
        // postcode_intensity
        let url = URL(string: link + "adduser/\(postcode)_\(intensity)")
        
        
        if let url = url {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    self.performUserID(data)
                }
            }.resume()
        }
        
    }
    
    //MARK: -add review in database
    func addReview(userid: String, activity: Activity, rate: Int) {
        let url = URL(string: link + "\(userid)_\(activity.activityID!)_\(rate)")
        if let url = url {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                }
                if let data = data {
                    print(data)
                }
            }.resume()
        }
    }
    
    // MARK: --Database Protocol
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .all {
            listener.getActivities(activities: activities)
        } else if listener.listenerType == .recommend {
            listener.getActivities(activities: recommendActivities)
        } else if listener.listenerType == .map {
            listener.addLocation(place: places)
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
}
