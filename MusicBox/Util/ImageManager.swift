//
//  ImageManager.swift
//  MusicBox
//
//  Created by https://stackoverflow.com/questions/35958826
//

import UIKit
import Combine

class ImageManager {
    static let shared = ImageManager()
    
    private init() { }
    
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: configuration)
        
        return session
    }()
    
    enum ImageManagerError: Error {
        case invalidResponse
    }
    
    func imagePublisher(for url: URL, errorImage: UIImage? = nil, handler: (() -> Void)? = nil) -> AnyPublisher<UIImage?, Never> {
        session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode,
                    let image = UIImage(data: data)
                else {
                    throw ImageManagerError.invalidResponse
                }
                
                handler?()
                
                return image
            }
            .replaceError(with: errorImage)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

