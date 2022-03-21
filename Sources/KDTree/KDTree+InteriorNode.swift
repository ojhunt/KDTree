//
//  InnerNode.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/19/22.
//

import VectorTypes

extension KDTree {
  @usableFromInline final class InteriorNode {
    @inlinable @inline(__always) init(children: (TreeNode, TreeNode), axis: T.AxisType, value: T.PointType.ValueType, bounds: BoundingBox<T.PointType>) {
      leftChild = .passRetained(children.0)
      rightChild = .passRetained(children.1)
      self.axis = axis
      self.value = value
      self.bounds = bounds
    }

    @usableFromInline @inline(__always) let leftChild: Unmanaged<TreeNode>
    @usableFromInline @inline(__always) let rightChild: Unmanaged<TreeNode>
    @usableFromInline @inline(__always) let axis: T.AxisType;
    @usableFromInline @inline(__always) let value: T.PointType.ValueType;
    @usableFromInline @inline(__always) let bounds: BoundingBox<T.PointType>;
  }
}

extension KDTree.InteriorNode : Sendable where T: Sendable, T.AxisType: Sendable, T.PointType: Sendable, T.PointType.ValueType: Sendable {
}
