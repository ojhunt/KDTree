//
//  InnerNode.swift
//  
//
//  Created by Oliver Hunt on 3/19/22.
//

@usableFromInline internal final class InnerNode<T: PositionedEntity> {
  internal init(children: (TreeNode<T>, TreeNode<T>), axis: T.AxisType, value: T.PointType.ValueType, bounds: BoundingBox<T.PointType>) {
    leftChild = children.0
    rightChild = children.1
    self.axis = axis
    self.value = value
    self.bounds = bounds
  }
  
  @usableFromInline let leftChild: TreeNode<T>
  @usableFromInline let rightChild: TreeNode<T>
  @usableFromInline let axis: T.AxisType;
  @usableFromInline let value: T.PointType.ValueType;
  @usableFromInline let bounds: BoundingBox<T.PointType>;
}

extension InnerNode : Sendable where T: Sendable, T.AxisType: Sendable, T.PointType: Sendable, T.PointType.ValueType: Sendable {
}
