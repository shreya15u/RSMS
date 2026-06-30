//
//  ImagePickerService.swift
//  luxury
//
//  Created by Codex on 20/05/26.
//

import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PickedImageAsset: Equatable {
    let data: Data
    let fileExtension: String
    let contentType: String
}

enum ImagePickerServiceError: LocalizedError {
    case noSelection
    case unsupportedType
    case emptyData
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .noSelection:
            return "Please select an image."
        case .unsupportedType:
            return "Selected file is not a supported image."
        case .emptyData:
            return "Selected image could not be loaded."
        case .invalidImageData:
            return "Captured image could not be processed."
        }
    }
}

final class ImagePickerService {
    func loadImage(from item: PhotosPickerItem?) async throws -> PickedImageAsset {
        guard let item else {
            throw ImagePickerServiceError.noSelection
        }

        guard item.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) else {
            throw ImagePickerServiceError.unsupportedType
        }

        guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
            throw ImagePickerServiceError.emptyData
        }
        
        guard let uiImage = UIImage(data: data) else {
            throw ImagePickerServiceError.invalidImageData
        }
        
        var compressionQuality: CGFloat = 0.8
        var compressedData = uiImage.jpegData(compressionQuality: compressionQuality)
        let maxByteCount = 2 * 1024 * 1024 // 2 MB
        
        while let currentData = compressedData, currentData.count > maxByteCount, compressionQuality > 0.1 {
            compressionQuality -= 0.1
            compressedData = uiImage.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalData = compressedData else {
            throw ImagePickerServiceError.invalidImageData
        }

        return PickedImageAsset(
            data: finalData,
            fileExtension: "jpg",
            contentType: "image/jpeg"
        )
    }

    func loadImage(from image: UIImage) throws -> PickedImageAsset {
        guard let data = image.jpegData(compressionQuality: 0.9), !data.isEmpty else {
            throw ImagePickerServiceError.invalidImageData
        }

        return PickedImageAsset(
            data: data,
            fileExtension: "jpg",
            contentType: "image/jpeg"
        )
    }
}
