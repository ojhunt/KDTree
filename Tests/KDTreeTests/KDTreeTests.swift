import XCTest
import VectorTypes

@testable import KDTree

struct IntComparator : PriorityComparator{
  typealias ValueType = Int
  static func value(_ left: Int, isLessThan right: Int) -> Bool {
    return left < right
  }
}
struct TestMask2D : Mask {
  let x: Bool
  let y: Bool
  
  var any: Bool { x || y}
  
  var none: Bool { !any }
  
  var all: Bool { x && y }
  
  subscript(_ axis: TestAxis2D) -> Bool {
    switch axis {
    case .x: return x
    case .y: return y
    }
  }
  
  typealias AxisType = TestAxis2D
}
struct TestVector2D : Vector {
  static prefix func - (right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: -right.x, y: -right.y)
  }
  
  static func + (left: TestVector2D, right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: left.x + right.x, y: left.y + right.y)
  }
  
  static func - (left: TestVector2D, right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: left.x - right.x, y: left.y - right.y)
  }
  
  func length() -> Float {
    return squaredLength().squareRoot()
  }
  
  func replace(with other: TestVector2D, where c: TestMask2D) -> TestVector2D {
    return TestVector2D(x: c.x ? other.x : x, y: c.y ? other.y : y)
  }
  
  func minElement() -> Float {
    return Swift.min(x, y)
  }
  
  func maxElement() -> Float {
    return Swift.max(x, y)
  }
  
  static func random() -> TestVector2D {
    return random(1)
  }
  
  static func random(_ radius: Float) -> TestVector2D {
    while true {
      let x = Float.random(in: -radius...radius)
      let y = Float.random(in: -radius...radius)
      if x*x+y*y <= 1 {
        return TestVector2D(x: x, y: y)
      }
    }
  }
  
  static func * (left: TestVector2D, right: Float) -> TestVector2D {
    return TestVector2D(x: left.x * right, y: left.y * right)
  }
  
  static func * (left: Float, right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: right.x * left, y: right.y * left)
  }
  
  static func / (left: TestVector2D, right: Float) -> TestVector2D {
    return TestVector2D(x: left.x / right, y: left.y / right)
  }
  
  static func .* (left: TestVector2D, right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: left.x * right.x, y: left.y * right.y )
  }
  
  static func ./ (left: TestVector2D, right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: left.x / right.x, y: left.y / right.y )
  }
  
  static func .< (left: TestVector2D, right: TestVector2D) -> TestMask2D {
    return TestMask2D(x: left.x < right.x, y: left.y < right.y )
  }
  
  static func .> (left: TestVector2D, right: TestVector2D) -> TestMask2D {
    return TestMask2D(x: left.x > right.x, y: left.y > right.y )
  }
  
  static func max(_ left: TestVector2D, _ right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: Swift.max(left.x, right.x), y: Swift.max(left.y, right.y))
  }
  
  static func min(_ left: TestVector2D, _ right: TestVector2D) -> TestVector2D {
    return TestVector2D(x: Swift.min(left.x, right.x), y: Swift.min(left.y, right.y))
  }
  
  typealias MaskType = TestMask2D
  
  internal init(x: Float, y: Float) {
    self.x = x
    self.y = y
  }
  
  let x: Float
  let y: Float
  subscript(axis: TestAxis2D) -> Float {
    switch axis {
    case .x: return x
    case .y: return y
    }
  }
  
  init(repeating splat: Float) {
    x = splat
    y = splat
  }
  
  typealias AxisType = TestAxis2D
  
  typealias ValueType = Float
  
  
}
struct TestPoint2D : Point {
  static func - (left: TestPoint2D, right: TestVector2D) -> TestPoint2D {
    return TestPoint2D(x: left.x - right.x, y: left.y - right.y)
  }
  
  static func + (left: TestPoint2D, right: TestVector2D) -> TestPoint2D {
    return TestPoint2D(x: left.x + right.x, y: left.y + right.y)
  }
  
  static func - (left: TestPoint2D, right: TestPoint2D) -> TestVector2D {
    return TestVector2D(x: left.x - right.x, y: left.y - right.y)
  }
  
  typealias MaskType = TestMask2D
  
  let x: Float
  let y: Float
  static var min = TestPoint2D(x: -Float.infinity, y: -Float.infinity)
  static var max = TestPoint2D(x: Float.infinity, y: Float.infinity)
  
  static func minElements(_ left: TestPoint2D, _ right: TestPoint2D) -> TestPoint2D {
    return TestPoint2D(x: Swift.min(left.x, right.x), y: Swift.min(left.y, right.y))
  }
  
  static func maxElements(_ left: TestPoint2D, _ right: TestPoint2D) -> TestPoint2D {
    return TestPoint2D(x: Swift.max(left.x, right.x), y: Swift.max(left.y, right.y))
  }
  
  subscript(axis: TestAxis2D) -> Float {
    switch axis {
    case .x: return x
    case .y: return y
    }
  }
  
  static func .< (left: TestPoint2D, right: TestPoint2D) -> MaskType {
    return MaskType(x: left.x < right.x, y: left.y < right.y)
  }
  
  static func .> (left: TestPoint2D, right: TestPoint2D) -> MaskType {
    return MaskType(x: left.x > right.x, y: left.y > right.y)
  }
  
  typealias AxisType = TestAxis2D
  typealias ValueType = Float
  typealias VectorType = TestVector2D
  
  
}
enum TestAxis2D : IterableAxis, CaseIterable {
  case x
  case y
}


final class KDTreeTests: XCTestCase {
  func testSort1() {
    var heap: ClampedPriorityHeap<Int, IntComparator> = ClampedPriorityHeap(maxSize: 12);
    for _ in 0..<100 {
      heap.insert(Int.random(in: -50..<50));
    }
    var result = [Int]()
    while let top = heap.pop() {
      result.append(top);
    }
    for i in 1..<result.count {
      XCTAssertGreaterThanOrEqual(result[i - 1], result[i]);
    }
  }

  func testSort2() {
    var heap = ClampedPriorityHeap<Int, IntComparator>(maxSize: 5);
    for i in 0..<10 {
      heap.insert(i);
    }
    var result = [Int]();
    while let top = heap.pop() {
      result.append(top);
    }
    for i in 1..<result.count {
      XCTAssertGreaterThanOrEqual(result[i - 1], result[i]);
    }
    XCTAssertEqual(result, [4, 3, 2, 1, 0]);
  }

  func test_sort3() {
    var heap = ClampedPriorityHeap<Int, IntComparator>(maxSize: 5);
    for i in 0..<10 {
      heap.insert(10 - 1 - i);
      heap.insert(10 - 1 - i);
    }
    var result = [Int]();
    while let top = heap.pop() {
      result.append(top);
    }
    for i in 1..<result.count {
      XCTAssertGreaterThanOrEqual(result[i - 1], result[i]);
    }
    XCTAssertEqual(result, [2, 1, 1, 0, 0]);
  }
  
  func test_select() {
    
    let comparator = { (a: Int, b: Int) -> CompareResult in
      if a < b { return .Less }
      if a > b { return .Greater }
      return .Equal
    }
    var array = ContiguousArray([5,2,1,0,4,3,6,7,8,9,10,11,12].shuffled())
    XCTAssertEqual(select(&array, kth: 0, by: comparator), 0);
    array.shuffle()
    XCTAssertEqual(select(&array, kth: 5, by: comparator), 5);
    array.shuffle()
    XCTAssertEqual(select(&array, kth: 1, by: comparator), 1);
    array.shuffle()
    XCTAssertEqual(select(&array, kth: 2, by: comparator), 2);
    array.shuffle()
    XCTAssertEqual(select(&array, kth: 3, by: comparator), 3);
    array.shuffle()
    XCTAssertEqual(select(&array, kth: 4, by: comparator), 4);
    
  }
  struct TestElement2D : PositionedEntity, Equatable {
    let position: TestPoint2D
    
    typealias PointType = TestPoint2D
    let id:Int
  }
  struct TestPair : Equatable {
    let value: TestElement2D
    let distance: Float
  }
  func test_buildComplete() {
    let range = Float(-100.0)..<Float(100.0)
    var points = ContiguousArray<TestElement2D>()
    for i in 0..<1000 {
      points.append(TestElement2D(position: TestPoint2D(x: Float.random(in: range), y: Float.random(in: range)), id: i))
    }
    _ = KDTree(elements: &points, maxChildren: 8)
  }
  func test_testVector() {
    XCTAssertEqual(TestVector2D(x: 1, y: 0).squaredLength(), 1.0)
    XCTAssertEqual(TestVector2D(x: 0, y: 1).squaredLength(), 1.0)
    XCTAssertEqual(TestVector2D(x: 1, y: 1).squaredLength(), 2.0)
  }
  func searchInteral(maxCount: Int, maxDistance: Float, filter: ((TestElement2D)->Float?)?) {
    let range = Float(-100.0)..<Float(100.0)
    var points = ContiguousArray<TestElement2D>()
    for i in 0..<1000 {
      points.append(TestElement2D(position: TestPoint2D(x: Float.random(in: range), y: Float.random(in: range)), id: i))
    }
    let tree = KDTree(elements: &points, maxChildren: 8)
    let position = TestPoint2D(x: Float.random(in: range), y: Float.random(in: range))
    let nearest = tree.nearest(position: position, maxCount: maxCount, maxDistance: maxDistance, filter: filter)?.sorted(by: { $0.distance < $1.distance}).map({ $0.element }) ?? []
    let maxSquaredDistance = maxDistance * maxDistance
    var accumulator = ElementAccumulator<TestElement2D, Float>(maxCount: maxCount)
    for element in points {
      guard let filter = filter else {
        let distance = (element.position - position).squaredLength()
        if (distance < maxSquaredDistance) {
          accumulator.insert(NonTupleType(element, distance));
        }
        continue;
      }
      guard let distance = filter(element) else { return }
      if (distance < maxDistance) {
        accumulator.insert(NonTupleType(element, distance));
      }
    }
    let sortedPoints = accumulator.getData().sorted(by: { $0.distance < $1.distance}).map({ $0.element })
    XCTAssertEqual(nearest, sortedPoints)
  }
  
  func test_basicSearch() {
    searchInteral(maxCount: 50, maxDistance: Float.infinity, filter: nil)
  }
  func test_boundSearch() {
    searchInteral(maxCount: 50, maxDistance: 5, filter: nil)
  }
  
  func test_filteredSearch() {
    let origin = TestPoint2D(x: 0, y: 0)
    searchInteral(maxCount: 50, maxDistance: Float.infinity) { element in
      if element.id.isMultiple(of: 2) {
        return nil
      } else {
        return (element.position - origin).length()
      }
    }
  }
}
