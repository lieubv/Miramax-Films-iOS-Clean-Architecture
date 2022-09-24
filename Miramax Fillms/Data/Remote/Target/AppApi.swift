//
//  AppApi.swift
//  Miramax Fillms
//
//  Created by Thanh Quang on 24/09/2022.
//

import Moya

enum AppApi {
    case personDetail(personId: Int)
}

extension AppApi: TargetType, NetworkConfigurable {
    var baseURL: URL {
        return baseApiURL
    }
    
    var path: String {
        switch self {
        case .personDetail(personId: let personId):
            return "person/\(personId)"
        }
    }
    
    var method: Moya.Method {
        .get
    }
    
    var task: Moya.Task {
        switch self {
        case .personDetail:
            return requestPersonDetail()
        }
    }
    
    var headers: [String : String]? {
        nil
    }
    
    private func requestPersonDetail() -> Moya.Task {
        let params: [String : Any] = [
            "api_key" : apiKey,
            "append_to_response" : "movie_credits,images,tv_credits"
        ]
        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
}
