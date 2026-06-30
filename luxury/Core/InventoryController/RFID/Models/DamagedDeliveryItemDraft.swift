//
//  DamagedDeliveryItemDraft.swift
//  luxury
//
//  Created by Codex on 26/05/26.
//

import Foundation

struct DamagedDeliveryItemDraft: Identifiable, Equatable {
    let serial: String
    let description: String
    let photo: PickedImageAsset

    var id: String {
        serial
    }
}
