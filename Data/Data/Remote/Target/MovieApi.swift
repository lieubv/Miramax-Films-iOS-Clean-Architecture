//
//  MovieApi.swift
//  Miramax Fillms
//
//  Created by Thanh Quang on 15/09/2022.
//

import Moya

enum MovieApi {
    case nowPlaying(genreId: Int?, page: Int?)
    case topRated(genreId: Int?, page: Int?)
    case popular(genreId: Int?, page: Int?)
    case upComing(genreId: Int?, page: Int?)
    case byGenre(genreId: Int, page: Int?)
    case detail(movieId: Int)
    case recommendations(movieId: Int, page: Int?)
}

extension MovieApi: TargetType, NetworkConfigurable {
    var baseURL: URL {
        return baseApiURL
    }
    
    var path: String {
        switch self {
        case .nowPlaying:
            return "movie/now_playing"
        case .topRated:
            return "movie/top_rated"
        case .popular:
            return "movie/popular"
        case .upComing:
            return "movie/upcoming"
        case .byGenre:
            return "discover/movie"
        case .detail(movieId: let movieId):
            return "movie/\(movieId)"
        case .recommendations(movieId: let movieId, page: _):
            return "movie/\(movieId)/recommendations"
        }
    }
    
    var method: Moya.Method {
        .get
    }
    
    var task: Moya.Task {
        switch self {
        case .nowPlaying(genreId: let genreId, page: let page):
            return requestWithGenreIdAndPageTask(genreId, page)
        case .topRated(genreId: let genreId, page: let page):
            return requestWithGenreIdAndPageTask(genreId, page)
        case .popular(genreId: let genreId, page: let page):
            return requestWithGenreIdAndPageTask(genreId, page)
        case .upComing(genreId: let genreId, page: let page):
            return requestWithGenreIdAndPageTask(genreId, page)
        case .byGenre(genreId: let genreId, page: let page):
            return requestWithGenreIdAndPageTask(genreId, page)
        case .detail:
            return requestMovieDetail()
        case .recommendations(movieId: _, page: let page):
            var params: [String : Any] = [
                "api_key" : apiKey
            ]
            if page != nil {
                params["page"] = page
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        nil
    }
    
    private func requestWithGenreIdAndPageTask(_ genreId: Int?, _ page: Int?) -> Moya.Task {
        var params: [String : Any] = [
            "api_key" : apiKey
        ]
        if genreId != nil {
            params["with_genres"] = genreId
        }
        if page != nil {
            params["page"] = page
        }
        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
    
    private func requestMovieDetail() -> Moya.Task {
        let params: [String : Any] = [
            "api_key" : apiKey,
            "append_to_response" : "credits,recommendations"
        ]
        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
}
