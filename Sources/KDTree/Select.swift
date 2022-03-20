//
//  Select.swift
//  Oliver's KDTree
//
//  Created by Oliver Hunt on 3/19/22.
//

import Foundation
@usableFromInline enum CompareResult : Equatable {
  case Less
  case Equal
  case Greater
}
@usableFromInline @inline(__always) func select<T>(_ array: inout [T], kth k: Int, left l: Int, right r: Int, by compare: (T, T) -> CompareResult) -> T {
  var left = l
  var right = r
  while right > left {
    if right - left > 600 {
      // I wrote this branch, but i have no idea why?
      let n = Float(right - left + 1)
      let i = Float(k - left + 1)
      let z = log(n)
      let s = 0.5 * exp(2 * z/3)
      let sd = 0.5 * sqrt(z * s * (n - s)/n) * ((i - n/2).sign == .plus ? 1 : -1)
      let newLeft = Swift.max(left, Int(Float(k) - i * s/n + sd))
      let newRight = Swift.min(right, Int(Float(k) + (n - i) * s/n + sd))
      _ = select(&array, kth: k, left: newLeft, right: newRight, by: compare)
    }
    
    var i = left + 1
    var j = right - 1
    array.swapAt(left, k)
    var tIndex : Int
    if compare(array[left], array[right]) != .Less {
      array.swapAt(left, right)
      tIndex = right
    } else {
      tIndex = left
    }
    let t = array[tIndex]
    while compare(array[i], t) == .Less {
      i += 1
    }
    while compare(array[j], t) == .Greater {
      j -= 1
    }
    
    while i < j {
      array.swapAt(i, j)
      i += 1
      j -= 1
      while compare(array[i], t) == .Less {
        i += 1
      }
      while compare(array[j], t) == .Greater {
        j -= 1
      }
    }
    if left == tIndex {
      array.swapAt(left, j)
    } else {
      j += 1
      array.swapAt(right, j)
    }
    if j <= k { left = j + 1 }
    if k <= j { right = Swift.max(j - 1, 0) }
  }
  return array[k]
}

@inlinable @inline(__always) func select<T>(_ array: inout [T], kth: Int, by areInIncreasingOrder: (T, T) -> CompareResult) -> T {
  return select(&array, kth: kth, left: 0, right: array.count - 1, by: areInIncreasingOrder)
}
