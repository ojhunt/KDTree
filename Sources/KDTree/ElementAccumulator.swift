//
//  ElementAccumulator.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/19/22.
//

import Foundation
public struct NonTupleType<Element, Distance> {
  internal init(_ element: Element, _ distance: Distance) {
    self.element = element
    self.distance = distance
  }
  
  public let element: Element
  public let distance: Distance
}

@usableFromInline internal struct ElementAccumulator<T, DistanceType: Comparable> {
  @usableFromInline struct DistanceComparator: PriorityComparator {
    @_effects(readnone) @inline(__always) @usableFromInline static func value(_ left: NonTupleType<T, DistanceType>, isLessThan right: NonTupleType<T, DistanceType>) -> Bool {
      return left.distance < right.distance
    }
    
    @usableFromInline typealias ValueType = NonTupleType<T, DistanceType>
    
    
  }
  @usableFromInline @inline(__always) var heap: ClampedPriorityHeap<NonTupleType<T, DistanceType>, DistanceComparator>?
  @usableFromInline @inline(__always) var data = ContiguousArray<NonTupleType<T, DistanceType>>()
  @usableFromInline @inline(__always) let maxCount: Int
  @usableFromInline @inline(__always) var count: Int = 0
  @usableFromInline @inline(__always) var topIndex: Int = -1
  @usableFromInline @inline(__always) init(maxCount: Int) {
    self.maxCount = maxCount
    heap = nil;
  }
  
  @usableFromInline @inline(__always) func getData() -> ContiguousArray<NonTupleType<T, DistanceType>> {
    if count == maxCount {
      return heap!.data
    }
    return data
  }
  @usableFromInline @inline(__always) var isEmpty : Bool { count == 0 }
  
  @usableFromInline @inline(__always) var sortedTop : NonTupleType<T, DistanceType>? {
    if count != maxCount {
      if topIndex >= 0 {
        return data[topIndex]
      }
    }
    return heap!.top;
  }
  
  @usableFromInline @inline(__always) var isFull : Bool {
    return count == maxCount;
  }
  
  @inlinable mutating func insert(_ newValue: NonTupleType<T, DistanceType>) {
    if count == maxCount {
      heap!.insert(newValue);
      return;
    }
    
    if topIndex >= 0 {
      if newValue.distance >= data[topIndex].distance {
        topIndex = data.count
      }
    } else {
      topIndex = data.count
    }
    assert(topIndex >= 0);
    data.append(newValue);
    count = data.count
    
    if count == maxCount {
      heap = ClampedPriorityHeap(maxSize: maxCount)
      heap!.append(contentsOf: data);
    }
  }
}
