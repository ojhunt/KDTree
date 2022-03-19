//
//  BoundingBox.swift
//  
//
//  Created by Oliver Hunt on 3/18/22.
//

public struct BoundingBox<PointType: Point> {
  typealias AxisType = PointType.AxisType
  
  public let minBound: PointType;
  public let maxBound: PointType;
  public init() {
    minBound = PointType.max
    maxBound = PointType.min
  }
  
  init(min: PointType, max: PointType) {
    self.minBound = min
    self.maxBound = max
  }
  
  public func maxAxis() -> PointType.AxisType {
    let range = maxBound - minBound;
    let cases = AxisType.allAxes
    let startIndex = cases.startIndex
    
    var max = cases[startIndex]
    var maxValue = range[max]
    for axis in cases {
      if range[axis] > maxValue {
        max = axis
        maxValue = range[axis]
      }
    }
    return max;
  }
  
  public func merge(other: Self) -> Self {
    return BoundingBox(min: PointType.minElements(minBound, other.minBound), max: PointType.maxElements(maxBound, other.maxBound))
  }
  
  public func merge(point: PointType) -> Self {
    return BoundingBox(min: PointType.minElements(minBound, point), max: PointType.maxElements(maxBound, point))
  }
}

extension BoundingBox : Sendable where PointType : Sendable {
  
}
