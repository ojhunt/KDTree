//
//  Vector.swift
//  
//
//  Created by Oliver Hunt on 3/18/22.
//

public protocol Vector {
  associatedtype AxisType
  associatedtype ValueType: Numeric & Comparable

  subscript(_ axis: AxisType) -> ValueType { get }
  init(splat: ValueType)
  func squaredLength() -> ValueType
}

extension Vector where AxisType: IterableAxis {
  func squaredLength() -> ValueType {
    var result : ValueType = ValueType.zero
    for axis in AxisType.allAxes {
      let value = self[axis]
      result += value * value
    }
    return result
  }
}

