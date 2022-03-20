//
//  TreeNode.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/19/22.
//

import Foundation
import VectorTypes
public protocol Rootable {
  associatedtype RootType: FloatingPoint
  func squareRoot() -> RootType;
}

extension Float: Rootable {
}
extension Double: Rootable {
}

@usableFromInline final class TreeNode<T: PositionedEntity> where T.PointType.ValueType: Rootable {
  @usableFromInline typealias DistanceType = T.PointType.ValueType
  @usableFromInline init(_ node: InnerNode<T>) {
    innerNode = node
    isLeaf = false
    leafChildren = []
    leafBounds = BoundingBox()
  }
  @usableFromInline init(_ leaf: ([T], BoundingBox<T.PointType>)) {
    leafChildren = leaf.0;
    leafBounds = leaf.1
    isLeaf = true
    innerNode = nil;
  }
  @usableFromInline @inline(__always) let innerNode: InnerNode<T>?
  @usableFromInline @inline(__always) let isLeaf: Bool
  @usableFromInline @inline(__always) let leafChildren: [T]
  @usableFromInline @inline(__always) let leafBounds: BoundingBox<T.PointType>
  @_effects(readnone) @usableFromInline @inline(__always) func nearest(
    position: T.PointType,
    maxCount: Int,
    maxDistance: DistanceType,
    filter: ((T)->DistanceType?)?
  ) -> [(T, DistanceType)]? {
    let maxSquaredDistance = maxDistance * maxDistance
    var nearestElements = ElementAccumulator<T, DistanceType>(maxCount: maxCount)
    var stack : [Unmanaged<TreeNode<T>>] = [.passUnretained(self)];
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
        top._withUnsafeGuaranteedRef({ top in top.leafChildren }).forEach { element in
          guard let filter = filter else {
            let distance = (element.position - position).squaredLength()
            if (distance < maxSquaredDistance) {
              nearestElements.insert((element, distance));
            }
            return;
          }
          guard let distance = filter(element) else { return }
          if (distance < maxDistance) {
            nearestElements.insert((element, distance));
          }
        }
        continue stack_loop;
      }
      
      let node : Unmanaged<InnerNode<T>> = top._withUnsafeGuaranteedRef({ top in
        return .passUnretained(top.innerNode!)
      })
      let nearestChild : Unmanaged<TreeNode>;
      let farthestChild : Unmanaged<TreeNode>?;
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
        let includeFarthest = (nodeValue - position[nodeAxis]) <= maxDistance
        (nearestChild, farthestChild, leftOfSplit) = (nodeLeftChild, includeFarthest ? nodeRightChild : nil, true)
      } else {
        let includeFarthest = (position[nodeAxis] - nodeValue) <= maxDistance
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
      let min = bounds.minBound - T.VectorType(repeating: Swift.min(distance, maxDistance));
      let max = bounds.maxBound + T.VectorType(repeating: Swift.min(distance, maxDistance));
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
  var bounds : BoundingBox<T.PointType> {
    if isLeaf {
      return leafBounds
    }
    return innerNode!.bounds
  }
}

extension TreeNode : Sendable where T: Sendable, T.PointType: Sendable, T.AxisType: Sendable, T.PointType.ValueType: Sendable {
  
}
