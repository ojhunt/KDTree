//
//  ClampedPriorityHeap.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/8/22.
//

public protocol PriorityComparator {
  associatedtype ValueType
  static func value(_ left: ValueType, isLessThan right: ValueType) -> Bool
}

@frozen public struct ClampedPriorityHeap<T, Comparator: PriorityComparator> where Comparator.ValueType == T {
  @usableFromInline var maxSize : Int
  @usableFromInline var data : ContiguousArray<T>
  @inlinable @inline(__always) init(maxSize: Int){
    self.maxSize = maxSize
    data = ContiguousArray()
    data.reserveCapacity(maxSize)
  }
  @usableFromInline @inline(__always) mutating func append(contentsOf buffer: ContiguousArray<T>) {
    for t in buffer {
      insert(t)
    }
  }
  @usableFromInline @inline(__always) var top : T? {
    return data.first
  }
  
  @usableFromInline mutating func pop() -> T? {
    guard let result = data.first else { return nil }

    if data.count == 1 {
      data.removeLast();
      return result;
    }

    let temp = data.removeLast()
    data[0] = temp;
    var currentIndex = 0;
    let end = data.count - 1
    while currentIndex * 2 < end {
      let leftChildIndex = currentIndex * 2 + 1;
      let rightChildIndex = currentIndex * 2 + 2;
      
      let left = data[leftChildIndex];
      if rightChildIndex == data.count {
        if Comparator.value(temp, isLessThan: left) {
          data.swapAt(currentIndex, leftChildIndex);
        }
        return result;
      }
      
      let right = data[rightChildIndex];
      if Comparator.value(left, isLessThan: temp) && Comparator.value(right, isLessThan: temp) {
        return result;
      }
      
      let greaterIndex = Comparator.value(left, isLessThan: right) ? rightChildIndex : leftChildIndex;
      data.swapAt(currentIndex, greaterIndex);
      currentIndex = greaterIndex;
    }
    return result;
  }

  @inlinable mutating func internalInsert(_ new: T) {
    assert(data.count < maxSize);
    var currentIndex = data.count;
    data.append(new);
    data.withContiguousMutableStorageIfAvailable { ptr in
      while currentIndex > 0 {
        let parentIndex = (currentIndex - 1) / 2;
        let parent = ptr.baseAddress!.advanced(by: parentIndex).pointee
        if Comparator.value(new, isLessThan: parent) {
          ptr.baseAddress!.advanced(by: currentIndex).initialize(to: new)
          return;
        }
        ptr.baseAddress!.advanced(by: currentIndex).initialize(to: parent)
        currentIndex = parentIndex;
      }
      ptr.baseAddress!.initialize(to: new)
    }
  }
  
  @inlinable mutating func insert(_ new: T) {
    if data.count >= maxSize {
      if Comparator.value(data[0], isLessThan: new) {
        return;
      }
      _ = pop();
    }
    internalInsert(new);
  }
}
