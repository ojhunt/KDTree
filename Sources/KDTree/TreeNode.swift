//
//  TreeNode.swift
//  
//
//  Created by Oliver Hunt on 3/18/22.
//

@usableFromInline internal enum Content<T: PositionedEntity> {
  case Leaf([T], BoundingBox<T.PointType>)
  case Inner(Unmanaged<InnerNode<T>>)
}
extension Content:
  Sendable where T: Sendable,
                 T.PointType: Sendable,
                 T.AxisType: Sendable,
                 T.PointType.ValueType: Sendable {
}

@usableFromInline final class TreeNode<T: PositionedEntity> {
  
  @usableFromInline init(_ node: InnerNode<T>) {
    content = .Inner(.passRetained(node))
  }
  @usableFromInline init(_ leaf: ([T], BoundingBox<T.PointType>)) {
    content = .Leaf(leaf.0, leaf.1)
  }
  
  @usableFromInline internal let content: Content<T>

  @usableFromInline var isLeaf: Bool {
    switch content {
    case .Leaf(_, _):
      return true
    case .Inner(_):
      return false
    }
  }
  
  @usableFromInline var childElements: [T] {
    switch content {
    case .Leaf(let children, _):
      return children
    case .Inner(_):
      fatalError()
    }
  }
  
  @usableFromInline var innerNode: Unmanaged<InnerNode<T>> {
    switch content {
    case .Leaf(_, _):
      fatalError()
    case .Inner(let node):
      return node
    }
  }
  
  @usableFromInline var bounds : BoundingBox<T.PointType> {
    switch content {
    case .Leaf(_, let bounds):
      return bounds
    case .Inner(let inner):
      return inner._withUnsafeGuaranteedRef { $0.bounds }
    }
  }
}


extension TreeNode : Sendable where T: Sendable,
                                      T.PointType: Sendable,
                                      T.AxisType: Sendable,
                                      T.PointType.ValueType: Sendable {
  
}

