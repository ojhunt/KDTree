//
//  PositionedEntity.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/18/22.
//

import VectorTypes

public protocol PositionedEntity {
  associatedtype PointType : Point
  typealias VectorType = PointType.VectorType
  typealias AxisType = PointType.AxisType
  var position: PointType { get };
}
