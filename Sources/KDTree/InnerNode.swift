//
//  InnerNode.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/19/22.
//

import VectorTypes

@usableFromInline final class InnerNode<T: PositionedEntity> where T.PointType.ValueType: Rootable {
  @inlinable @inline(__always) init(children: (TreeNode<T>, TreeNode<T>), axis: T.AxisType, value: T.PointType.ValueType, bounds: BoundingBox<T.PointType>) {
    leftChild = children.0
    rightChild = children.1
    self.axis = axis
    self.value = value
    self.bounds = bounds
  }

  @usableFromInline @inline(__always) let leftChild: TreeNode<T>
  @usableFromInline @inline(__always) let rightChild: TreeNode<T>
  @usableFromInline @inline(__always) let axis: T.AxisType;
  @usableFromInline @inline(__always) let value: T.PointType.ValueType;
  @usableFromInline @inline(__always) let bounds: BoundingBox<T.PointType>;
}

extension InnerNode : Sendable where T: Sendable, T.AxisType: Sendable, T.PointType: Sendable, T.PointType.ValueType: Sendable {
}
