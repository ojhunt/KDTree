//
//  KDTree.swift
//  Oliver's Incredible Device Simulator of Wonder
//
//  Created by Oliver Hunt on 3/8/22.
//
import Foundation
import VectorTypes

public typealias Point = VectorTypes.Point
public typealias Vector = VectorTypes.IndexableVector
public typealias Mask = VectorTypes.Mask
public typealias IterableAxis = VectorTypes.IterableAxis

@usableFromInline internal struct ElementAccumulator<T, DistanceType: Comparable> {
  @usableFromInline struct DistanceComparator: PriorityComparator {
    @usableFromInline static func value(_ left: (T, DistanceType), isLessThan right: (T, DistanceType)) -> Bool {
      return left.1 < right.1
    }
    
    @usableFromInline typealias ValueType = (T, DistanceType)
    
    
  }
  @usableFromInline var heap: ClampedPriorityHeap<(T, DistanceType), DistanceComparator>?
  @usableFromInline var data = [(T, DistanceType)]()
  @usableFromInline let maxCount: Int
  @usableFromInline var count: Int = 0
  @usableFromInline var topIndex: Int = -1
  @usableFromInline @inline(__always) init(maxCount: Int) {
    self.maxCount = maxCount
    heap = nil;
  }
  
  @usableFromInline @inline(__always) func getData() -> [(T, DistanceType)] {
    if count == maxCount {
      return heap!.data
    }
    return data
  }
  @usableFromInline @inline(__always) var isEmpty : Bool { count == 0 }
  
  @usableFromInline @inline(__always) var sortedTop : (T, DistanceType)? {
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
  
  @inlinable mutating func insert(_ newValue: (T, DistanceType)) {
    if count == maxCount {
      heap!.insert(newValue);
      return;
    }
    
    if topIndex >= 0 {
      if newValue.1 >= data[topIndex].1 {
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

public final class KDTree<T: PositionedEntity> {
  @usableFromInline let root: TreeNode<T>
  
  public init(elements: inout [T], maxChildren: Int) {
    let bounds = elements.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})
    root = buildKDTree(elements: &elements, bounds: bounds, maxChildren: maxChildren)
  }
  
  @inlinable public func nearest(
    position: T.PointType,
    maxCount: Int,
    maxDistance: T.PointType.ValueType,
    filter: ((T)->Bool)?
  ) -> [(T, T.PointType.ValueType)]? where T.PointType.ValueType: FloatingPoint {
    return nearest(position: position, maxCount: maxCount, maxDistanceSquared: maxDistance * maxDistance, filter: filter);
  }
  
  @inlinable public func nearest(
    position: T.PointType,
    maxCount: Int,
    maxDistanceSquared: T.PointType.ValueType,
    filter: ((T)->Bool)?
  ) -> [(T, T.PointType.ValueType)]? {
    var nearestElements = ElementAccumulator<T, T.PointType.ValueType>(maxCount: maxCount)
    var stack : [Unmanaged<TreeNode<T>>] = [.passUnretained(root)];
    stack_loop: while !stack.isEmpty {
      let top = stack.removeLast()
      if top._withUnsafeGuaranteedRef({top in top.isLeaf}) {
        let bounds = top._withUnsafeGuaranteedRef { top in
          top.bounds
        }
        if nearestElements.isFull {
          let distance = T.VectorType(repeating: nearestElements.sortedTop!.1);
          let min = bounds.minBound - distance;
          let max = bounds.maxBound + distance;
          if (position .< min).any || (position .> max).any {
            continue stack_loop;
          }
        }
        top._withUnsafeGuaranteedRef({ top in top.childElements }).forEach { element in
          if let filter = filter {
            if !filter(element) {
              return
            }
          }
          let distance = (element.position - position).squaredLength()
          if (distance < maxDistanceSquared) {
            nearestElements.insert((element, distance));
          }
        }
        continue stack_loop;
      }
      
      let node : Unmanaged<InnerNode<T>> = top._withUnsafeGuaranteedRef({ top in
        return top.innerNode
      })
      let nearestChild : Unmanaged<TreeNode<T>>;
      let farthestChild : Unmanaged<TreeNode<T>>?;
      let leftOfSplit : Bool;
      let nodeAxis = node._withUnsafeGuaranteedRef { node in
        node.axis
      }
      let nodeValue = node._withUnsafeGuaranteedRef { node in
        node.value
      }
      let nodeLeftChild : Unmanaged<TreeNode> = node._withUnsafeGuaranteedRef { node in
          .passUnretained(node.leftChild)
      }
      let nodeRightChild : Unmanaged<TreeNode> = node._withUnsafeGuaranteedRef { node in
          .passUnretained(node.rightChild)
      }

      if position[nodeAxis] < nodeValue {
        let includeFarthest = (nodeValue - position[nodeAxis]) <= maxDistanceSquared
        (nearestChild, farthestChild, leftOfSplit) = (nodeLeftChild, includeFarthest ? nodeRightChild : nil, true)
      } else {
        let includeFarthest = (position[nodeAxis] - nodeValue) <= maxDistanceSquared
        (nearestChild, farthestChild, leftOfSplit) = (nodeRightChild, includeFarthest ? nodeLeftChild : nil, false)
      }
      if !nearestElements.isFull {
        // we push the farthest first so we visit it second
        if let farthestChild = farthestChild {
          stack.append(farthestChild)
        }
        stack.append(nearestChild)
        continue stack_loop;
      }
      guard let distance = nearestElements.sortedTop?.1 else { fatalError() }
      let bounds = node._withUnsafeGuaranteedRef({ node in node.bounds });
      let min = bounds.minBound - T.VectorType(repeating: Swift.min(distance, maxDistanceSquared));
      let max = bounds.maxBound + T.VectorType(repeating: Swift.min(distance, maxDistanceSquared));
      if (position .< min).any || (position .> max).any {
        continue stack_loop;
      }
      
      if !leftOfSplit {
        if let farthestChild = farthestChild {
          
          if position[nodeAxis] + distance >= nodeValue {
            stack.append(farthestChild);
          }
        }
      } else {

        if let farthestChild = farthestChild {
          if position[nodeAxis] - distance <= nodeValue {
            stack.append(farthestChild);
          }
        }
      }

      stack.append(nearestChild);
    }
    if nearestElements.isEmpty {
      return nil
    }
    return nearestElements.getData()
  }
}

extension KDTree : Sendable where T: Sendable,
                                  T.AxisType: Sendable,
                                  T.PointType: Sendable,
                                  T.VectorType: Sendable,
                                  T.PointType.ValueType: Sendable {
}

enum CompareResult : Equatable {
  case Less
  case Equal
  case Greater
}

private func select<T>(array: inout [T], kth k: Int, left l: Int, right r: Int, by compare: (T, T) -> CompareResult) -> T {
  var left = l
  var right = r
  while right > left {
    if right - left > 600 {
      // I wrote this branch, but i have no idea why?
      let n = Double(right - left + 1)
      let i = Double(k - left + 1)
      let z = log(n)
      let s = 0.5 * exp(2 * z/3)
      let sd = 0.5 * sqrt(z * s * (n - s)/n) * ((i - n/2).sign == .plus ? 1 : -1)
      let newLeft = Swift.max(left, Int(Double(k) - i * s/n + sd))
      let newRight = Swift.min(right, Int(Double(k) + (n - i) * s/n + sd))
      _ = select(array: &array, kth: k, left: newLeft, right: newRight, by: compare)
    }
    
    var i = left + 1
    var j = right - 1
    array.swapAt(left, k)
    var tIndex : Int
    if compare(array[left], array[right]) != .Less {
      array.swapAt(left, right)
      tIndex = right
    } else {
      tIndex = left
    }
    let t = array[tIndex]
    while compare(array[i], t) == .Less {
      i += 1
    }
    while compare(array[j], t) == .Greater {
      j -= 1
    }
    
    while i < j {
      array.swapAt(i, j)
      i += 1
      j -= 1
      while compare(array[i], t) == .Less {
        i += 1
      }
      while compare(array[j], t) == .Greater {
        j -= 1
      }
    }
    if left == tIndex {
      array.swapAt(left, j)
    } else {
      j += 1
      array.swapAt(right, j)
    }
    if j <= k { left = j + 1 }
    if k <= j { right = Swift.max(j - 1, 0) }
  }
  return array[k]
}

func select<T>(array: inout [T], kth: Int, by areInIncreasingOrder: (T, T) -> CompareResult) -> T {
  return select(array: &array, kth: kth, left: 0, right: array.count - 1, by: areInIncreasingOrder)
}

internal func buildKDTree<T: PositionedEntity>(elements: inout [T], bounds: BoundingBox<T.PointType>, maxChildren: Int) -> TreeNode<T> {
  if elements.count < maxChildren {
    return TreeNode((elements, bounds))
  }
  let maxAxis = bounds.maxAxis()
  let halfPoint = elements.count / 2
  _ = select(array: &elements, kth: halfPoint, by: { a, b in
    let l = a.position[maxAxis]
    let r = b.position[maxAxis]
    if l < r { return .Less }
    if l > r { return .Greater }
    return .Equal
  })
  let splitValue = elements[halfPoint].position[maxAxis];
  
  var left : [T] = elements[0..<halfPoint].map({a in a})
  var right : [T] = elements[halfPoint..<elements.count].map({a in a})
  assert(left.last!.position[maxAxis] <= right.last!.position[maxAxis])
  assert(left.first!.position[maxAxis] <= right.first!.position[maxAxis])
  let leftBounds = left.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})
  let rightBounds = right.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})

  let leftNode = buildKDTree(elements: &left, bounds: leftBounds, maxChildren: maxChildren)
  let rightNode = buildKDTree(elements: &right, bounds: rightBounds, maxChildren: maxChildren)

  let innerNode = InnerNode(children:(leftNode, rightNode), axis: maxAxis, value:splitValue, bounds:bounds);
  
  return TreeNode(innerNode)
}
