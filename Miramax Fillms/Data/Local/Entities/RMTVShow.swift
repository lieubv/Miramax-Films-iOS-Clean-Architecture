//
//  RMTVShow.swift
//  Miramax Fillms
//
//  Created by Thanh Quang on 25/09/2022.
//

import RealmSwift

final class RMTVShow: Object {
    @Persisted(primaryKey: true) var _id: Int = 0
    @Persisted var name: String = ""
    @Persisted var backdropPath: String?
    @Persisted var posterPath: String?
    @Persisted var overview: String = ""
    @Persisted var voteAverage: Double = 0.0
}

extension RMTVShow: DomainConvertibleType {
    func asDomain() -> TVShow {
        return TVShow(
            id: _id,
            name: name,
            backdropPath: backdropPath,
            posterPath: posterPath,
            overview: overview,
            voteAverage: voteAverage
        )
    }
}

extension TVShow: RealmRepresentable {
    func asRealm() -> RMTVShow {
        return RMTVShow.build { object in
            object._id = id
            object.name = name
            object.backdropPath = backdropPath
            object.posterPath = posterPath
            object.overview = overview
            object.voteAverage = voteAverage
        }
    }
}
