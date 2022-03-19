//
//  Mask.swift
//  
//
//  Created by Oliver Hunt on 3/18/22.
//

public protocol Mask {
  associatedtype AxisType
  var any : Bool { get }
  var none : Bool { get }
  var all : Bool { get }
  subscript (_ axis: AxisType) -> Bool { get }
}
