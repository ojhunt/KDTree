import XCTest
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
  
  init(splat: Float) {
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
    var array = [5,2,1,0,4,3,6,7,8,9,10,11,12].shuffled()
    XCTAssertEqual(select(array: &array, kth: 0, by: comparator), 0);
    array.shuffle()
    XCTAssertEqual(select(array: &array, kth: 5, by: comparator), 5);
    array.shuffle()
    XCTAssertEqual(select(array: &array, kth: 1, by: comparator), 1);
    array.shuffle()
    XCTAssertEqual(select(array: &array, kth: 2, by: comparator), 2);
    array.shuffle()
    XCTAssertEqual(select(array: &array, kth: 3, by: comparator), 3);
    array.shuffle()
    XCTAssertEqual(select(array: &array, kth: 4, by: comparator), 4);
    
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
    var points = [TestElement2D]()
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
  func searchInteral(maxDistance: Float, filter: ((TestElement2D)->Bool)?) {
    let range = Float(-100.0)..<Float(100.0)
    var points = [TestElement2D]()
    for i in 0..<1000 {
      points.append(TestElement2D(position: TestPoint2D(x: Float.random(in: range), y: Float.random(in: range)), id: i))
    }
    let tree = KDTree(elements: &points, maxChildren: 8)
    let position = TestPoint2D(x: Float.random(in: range), y: Float.random(in: range))
    let nearest = tree.nearest(position: position, maxCount: 50, maxDistanceSquared: maxDistance, filter: filter)?.sorted(by: { $0.1 < $1.1}).map({ $0.0 }) ?? []
    var truePointAndDistance = [TestPair]()
    for point in points {
      let distance = (point.position - position).squaredLength()
      if let filter = filter {
        if !filter(point) {
          continue
        }
      }
      truePointAndDistance.append(TestPair(value: point, distance: distance))
    }
    let sortedPoints = truePointAndDistance.filter({ elem in
      elem.distance < maxDistance
    }).sorted(by: { $0.distance < $1.distance})[0..<nearest.count].map({$0.value})
    
    XCTAssertEqual(nearest, sortedPoints)
  }
  
  func test_basicSearch() {
    searchInteral(maxDistance: Float.infinity, filter: nil)
  }
  func test_boundSearch() {
    searchInteral(maxDistance: 5, filter: nil)
  }
  
  func test_filteredSearch() {
    searchInteral(maxDistance: Float.infinity) { element in
      return element.id.isMultiple(of: 2)
    }
  }
}
