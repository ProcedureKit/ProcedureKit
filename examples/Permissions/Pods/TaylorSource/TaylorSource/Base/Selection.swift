//
//  Selection.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 17/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

struct SelectionState<Item: Hashable> {
    var selectedItems = Set<Item>()
    init(initialSelection: Set<Item> = Set()) {
        selectedItems.unionInPlace(initialSelection)
    }
}

public class SelectionManager<Item: Hashable> {

    let state: Protector<SelectionState<Item>>

    public var allowsMultipleSelection = false
    public var enabled = false

    public var selectedItems: Set<Item> {
        return state.read { $0.selectedItems }
    }

    public init(initialSelection: Set<Item> = Set()) {
        state = Protector(SelectionState(initialSelection: initialSelection))
    }

    public func contains(item: Item) -> Bool {
        return state.read { $0.selectedItems.contains(item) }
    }

    public func selectItem(item: Item, shouldRefreshItems: ((itemsToRefresh: [Item]) -> Void)? = .None) {
        if enabled {
            var itemsToUpdate = Set(arrayLiteral: item)
            state.write({ (inout state: SelectionState<Item>) in
                if state.selectedItems.contains(item) {
                    state.selectedItems.remove(item)
                }
                else {
                    if !self.allowsMultipleSelection {
                        itemsToUpdate.unionInPlace(state.selectedItems)
                        state.selectedItems.removeAll(keepCapacity: true)
                    }
                    state.selectedItems.insert(item)
                }
            }, completion: {
                shouldRefreshItems?(itemsToRefresh: Array(itemsToUpdate))
            })
        }
    }
}

public typealias IndexPathSelectionManager = SelectionManager<NSIndexPath>

