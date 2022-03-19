//
//  PositionedValue.swift
//  
//
//  Created by Oliver Hunt on 3/18/22.
//

public protocol PositionedEntity {
  associatedtype PointType : Point
  typealias VectorType = PointType.VectorType
  typealias AxisType = PointType.AxisType
  var position: PointType { get };
}
