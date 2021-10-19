//
//  ImageManager.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/11.
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
    
    func imagePublisher(for url: URL, errorImage: UIImage? = nil) -> AnyPublisher<UIImage?, Never> {
        session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode,
                    let image = UIImage(data: data)
                else {
                    throw ImageManagerError.invalidResponse
                }
                
                return image
            }
            .replaceError(with: errorImage)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

