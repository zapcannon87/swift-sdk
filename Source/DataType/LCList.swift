//
//  LCList.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/27/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud list type.

 It is a wrapper of NSArray type, used to store a list of objects.
 */
public class LCList: LCType, ArrayLiteralConvertible {
    public typealias Element = LCType

    public private(set) var value: [Element]?

    public required init() {
        super.init()
    }

    public convenience init(_ value: [Element]) {
        self.init()
        self.value = value
    }

    public convenience required init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    public override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! LCList
        copy.value = value
        return copy
    }

    override public func isEqual(another: AnyObject?) -> Bool {
        if another === self {
            return true
        } else if let another = another as? LCList {
            let lhs = value
            let rhs = another.value

            if let lhs = lhs, rhs = rhs {
                return lhs == rhs
            } else if lhs == nil && rhs == nil {
                return true
            }
        }

        return false
    }

    override class func operationReducerType() -> OperationReducer.Type {
        return OperationReducer.List.self
    }

    /**
     Append an element.

     - parameter element: The element to be appended.
     */
    public func append(element: Element) {
        self.value = concatenateObjects([element])

        updateParent { (object, key) in
            object.addOperation(.Add, key, LCList([element]))
        }
    }

    /**
     Append an element with unique option.

     This method will append an element based on the `unique` option.
     If `unique` is true, element will not be appended if it had already existed in array.
     Otherwise, the element will always be appended.

     - parameter element: The element to be appended.
     - parameter unique:  Unique or not.
     */
    public func append(element: Element, unique: Bool) {
        self.value = concatenateObjects([element], unique: unique)

        updateParent { (object, key) in
            object.addOperation(.AddUnique, key, LCList([element]))
        }
    }

    /**
     Remove an element from list.

     - parameter element: The element to be removed.
     */
    public func remove(element: Element) {
        self.value = subtractObjects([element])

        updateParent { (object, key) -> Void in
            object.addOperation(.Remove, key, LCList([element]))
        }
    }

    /**
     Concatenate objects.

     - parameter another: Another array of objects to be concatenated.

     - returns: A new concatenated array.
     */
    func concatenateObjects(another: [Element]?) -> [Element]? {
        return concatenateObjects(another, unique: false)
    }

    /**
     Concatenate objects with unique option.

     If unique is true, element in another array will not be concatenated if it had existed.

     - parameter another: Another array of objects to be concatenated.
     - parameter unique:  Unique or not.

     - returns: A new concatenated array.
     */
    func concatenateObjects(another: [Element]?, unique: Bool) -> [Element]? {
        guard let another = another else {
            return self.value
        }

        var result = self.value ?? []

        if unique {
            another.forEach({ (element) in
                if !result.contains(element) {
                    result.append(element)
                }
            })
        } else {
            result.appendContentsOf(another)
        }

        return result
    }

    /**
     Subtract objects.

     - parameter another: Another array of objects to be subtracted.

     - returns: A new subtracted array.
     */
    func subtractObjects(another: [Element]?) -> [Element]? {
        guard let minuend = self.value else {
            return nil
        }

        guard let subtrahend = another else {
            return minuend
        }

        return minuend.filter { !subtrahend.contains($0) }
    }

    // MARK: Arithmetic

    override func add(another: LCType?) -> LCType? {
        return add(another, unique: false)
    }

    override func add(another: LCType?, unique: Bool) -> LCType? {
        guard let another = another as? LCList else {
            /* TODO: throw an exception that one type cannot be appended to another type. */
            return nil
        }

        if let array = concatenateObjects(another.value, unique: unique) {
            return LCList(array)
        } else {
            return LCList()
        }
    }

    override func subtract(another: LCType?) -> LCType? {
        guard let another = another as? LCList else {
            /* TODO: throw an exception that one type cannot be appended to another type. */
            return nil
        }

        if let array = subtractObjects(another.value) {
            return LCList(array)
        } else {
            return LCList()
        }
    }
}