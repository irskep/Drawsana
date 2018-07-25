//
//  AMDrawingTool.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public protocol AMToolStateAppliable {
  func apply(state: AMGlobalToolState)
}

// MARK: Main protocol

public protocol AMDrawingTool: AMToolStateAppliable {
  var isProgressive: Bool { get }

  func activate()
  func deactivate()

  func drawPoint(_ point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState)
  func drawStart(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState)
  func drawContinue(point: CGPoint, velocity: CGPoint, drawing: AMDrawing, state: AMGlobalToolState)
  func drawEnd(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState)

  func apply(state: AMGlobalToolState)

  func renderShapeInProgress(transientContext: CGContext)
}
public extension AMDrawingTool {
  func activate() { }
  func deactivate() { }
  func apply(state: AMGlobalToolState) { }
  func renderShapeInProgress(transientContext: CGContext) { }
}

// MARK: Convenience protocol: automatically render shapeInProgress

public protocol AMShapeInProgressRendering {
  associatedtype ShapeType: AMShape
  var shapeInProgress: ShapeType? { get }
}
extension AMShapeInProgressRendering {
  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
}

// MARK: Convenience superclass: create and update shapeInProgress by dragging from point A to point B

public class AMDrawingToolForShapeWithTwoPoints: AMDrawingTool {
  public typealias ShapeType = AMShape & AMShapeWithTwoPoints & AMToolStateAppliable

  public var shapeInProgress: ShapeType?

  func makeShape() -> ShapeType {
    fatalError("Override me")
  }

  public var isProgressive: Bool { return false }

  public init() { }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    var shape = makeShape()
    shape.a = point
    shape.b = point
    shape.apply(state: state)
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    shapeInProgress = makeShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
    shapeInProgress?.apply(state: state)
  }

  public func drawContinue(point: CGPoint, velocity: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    shapeInProgress?.b = point
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    shapeInProgress?.b = point
    drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
}

// MARK: Tools

public class AMLineTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMLineShape() }
}

public class AMRectTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMRectShape() }
}

public class AMEllipseTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMEllipseShape() }
}

public class AMPenTool: AMDrawingTool, AMShapeInProgressRendering {
  public typealias ShapeType = AMPenShape

  public var shapeInProgress: AMPenShape?

  public var isProgressive: Bool { return true }

  private var lastVelocity: CGPoint = .zero

  public var velocityBasedWidth: Bool = true

  public init() { }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    let shape = AMPenShape()
    shape.start = point
    shape.isFinished = false
    shape.apply(state: state)
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    lastVelocity = .zero
    shapeInProgress = AMPenShape()
    shapeInProgress?.start = point
    shapeInProgress?.apply(state: state)
  }

  public func drawContinue(point: CGPoint, velocity: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    guard let shape = shapeInProgress else { return }
    let lastPoint = shape.segments.last?.b ?? shape.start
    let segmentWidth: CGFloat

    if velocityBasedWidth {
      segmentWidth = AMDrawingUtils.modulatedWidth(
        width: shape.strokeWidth,
        velocity: velocity,
        previousVelocity: lastVelocity,
        previousWidth: shape.segments.last?.width ?? shape.strokeWidth)
    } else {
      segmentWidth = shape.strokeWidth
    }
    shape.add(segment: AMLineSegment(a: lastPoint, b: point, width: segmentWidth))
    lastVelocity = velocity
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    shapeInProgress?.isFinished = true
    drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.renderLatestSegment(in: transientContext)
  }
}

public class AMEraserTool: AMPenTool {
  public override init() {
    super.init()
    velocityBasedWidth = false
  }

  public override func drawStart(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    super.drawStart(point: point, drawing: drawing, state: state)
    shapeInProgress?.isEraser = true
  }
}

class AMDrawingUtils {
  class func modulatedWidth(width: CGFloat, velocity: CGPoint, previousVelocity: CGPoint, previousWidth: CGFloat) -> CGFloat {
    let velocityAdjustement: CGFloat = 600.0
    let speed = velocity.length / velocityAdjustement
    let previousSpeed = previousVelocity.length / velocityAdjustement

    let modulated = width / (0.6 * speed + 0.4 * previousSpeed)
    let limited = clamp(value: modulated, min: 0.75 * previousWidth, max: 1.25 * previousWidth)
    let final = clamp(value: limited, min: 0.2*width, max: width)

    return final
  }
}


extension CGPoint {
  var length: CGFloat {
    return sqrt((self.x*self.x) + (self.y*self.y))
  }
}


func clamp<T: Comparable>(value: T, min: T, max: T) -> T {
  if (value < min) {
    return min
  }

  if (value > max) {
    return max
  }

  return value
}

