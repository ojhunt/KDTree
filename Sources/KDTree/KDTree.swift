//
//  KDTree.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/18/22.
//

import Foundation
import VectorTypes

@frozen public struct KDTree<T: PositionedEntity> where T.PointType.ValueType: Rootable {
  public typealias DistanceType = T.PointType.ValueType
  @usableFromInline let root: TreeNode
  
  @inlinable @inline(__always) public init(elements: inout ContiguousArray<T>, maxChildren: Int) {
    let bounds = elements.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})
    root = buildKDTree(elements: &elements, bounds: bounds, maxChildren: maxChildren)
  }
  @inlinable @inline(__always) public func nearest(
    position: T.PointType,
    maxCount: Int,
    maxDistance: DistanceType,
    filter: ((T)->DistanceType?)? = nil
  ) -> ContiguousArray<(T, T.PointType.ValueType)>? {
    return root.nearest(position: position, maxCount: maxCount, maxDistance: maxDistance, filter: filter);
  }
}

extension KDTree : Sendable
where T: Sendable, T.AxisType: Sendable, T.PointType: Sendable, T.VectorType: Sendable, T.PointType.ValueType: Sendable {
  
}

@_effects(releasenone) @usableFromInline @inline(__always) func buildKDTree<T: PositionedEntity>(elements: inout ContiguousArray<T>, bounds: BoundingBox<T.PointType>, maxChildren: Int) -> KDTree<T>.TreeNode {
  if elements.count < maxChildren {
    return KDTree<T>.TreeNode((elements, bounds))
  }
  let maxAxis = bounds.maxAxis()
  let halfPoint = elements.count / 2
  _ = select(&elements, kth: halfPoint, by: { a, b in
    let l = a.position[maxAxis]
    let r = b.position[maxAxis]
    if l < r { return .Less }
    if l > r { return .Greater }
    return .Equal
  })
  let splitValue = elements[halfPoint].position[maxAxis];
  
  var left = ContiguousArray(elements[0..<halfPoint])
  var right = ContiguousArray(elements[halfPoint..<elements.count])
  assert(left.last!.position[maxAxis] <= right.last!.position[maxAxis])
  assert(left.first!.position[maxAxis] <= right.first!.position[maxAxis])
  let leftBounds = left.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})
  let rightBounds = right.reduce(BoundingBox(), { result, element in return result.merge(point:element.position)})
  let leftNode = buildKDTree(elements: &left, bounds: leftBounds, maxChildren: maxChildren)
  let rightNode = buildKDTree(elements: &right, bounds: rightBounds, maxChildren: maxChildren)
  return KDTree<T>.TreeNode(KDTree<T>.InteriorNode(children:(leftNode, rightNode), axis: maxAxis, value:splitValue, bounds:bounds))
}
