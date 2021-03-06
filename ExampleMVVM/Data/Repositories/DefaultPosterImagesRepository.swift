//
//  DefaultPosterImagesRepository.swift
//  ExampleMVVM
//
//  Created by Oleh Kudinov on 01.10.18.
//

import Foundation

final class DefaultPosterImagesRepository {
    
    private let dataTransferService: DataTransferService
    private let imageNotFound: Data?
    
    init(dataTransferService: DataTransferService,
         imageNotFound: Data?) {
        self.dataTransferService = dataTransferService
        self.imageNotFound = imageNotFound
    }
}

extension DefaultPosterImagesRepository: PosterImagesRepository {
    
    func fetchImage(with imagePath: String, width: Int, completion: @escaping (Result<Data, RepositoryError>) -> Void) -> Cancellable? {
        
        let endpoint = APIEndpoints.getMoviePoster(path: imagePath, width: width)
        let task = RepositoryTask()
        task.networkTask = dataTransferService.request(with: endpoint) { [weak self] (result: Result<Data, DataTransferError>) in
            guard let self = self else { return }

            let result = result.flatMapError(self.handleError)
            DispatchQueue.main.async { completion(result) }
        }
        return task
    }

    private func handleError(_ error: DataTransferError) -> Result<Data, RepositoryError> {
        guard case let .networkFailure(networkError) = error,
            networkError.isNotFoundError,
            let imageNotFound = self.imageNotFound else { return .failure(.dataTransfer(error)) }

        return .success(imageNotFound)
    }
}
