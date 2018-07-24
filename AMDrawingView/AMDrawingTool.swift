//
//  AMDrawingTool.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class AMLineTool: AMDrawingToolWithShapeInProgress {
  public typealias ShapeType = AMLineShape

  public var shapeInProgress: AMLineShape?

  public var isProgressive: Bool { return false }

  public init() {

  }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing) {
    let shape = AMLineShape()
    shape.a = point
    shape.b = point
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress = AMLineShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
  }

  public func drawContine(point: CGPoint, velocity: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
    drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }
}

public class AMRectTool: AMDrawingToolWithShapeInProgress {
  public typealias ShapeType = AMRectShape

  public var shapeInProgress: AMRectShape?

  public var isProgressive: Bool { return false }

  public init() {

  }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing) {
    let shape = AMRectShape()
    shape.a = point
    shape.b = point
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress = AMRectShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
  }

  public func drawContine(point: CGPoint, velocity: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
    drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }
}

public class AMEllipseTool: AMDrawingToolWithShapeInProgress {
  public typealias ShapeType = AMEllipseShape

  public var shapeInProgress: AMEllipseShape?

  public var isProgressive: Bool { return false }

  public init() {

  }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing) {
    let shape = AMEllipseShape()
    shape.a = point
    shape.b = point
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress = AMEllipseShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
  }

  public func drawContine(point: CGPoint, velocity: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing) {
    shapeInProgress?.b = point
    drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }
}

public class AMPenTool: AMDrawingToolWithShapeInProgress {
  public typealias ShapeType = AMPenShape

  public var shapeInProgress: AMPenShape?

  public var isProgressive: Bool { return true }

  private var lastVelocity: CGPoint = .zero

  public var velocityBasedWidth: Bool = true

  public init() {

  }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing) {
    let shape = AMPenShape()
    shape.start = point
    shape.isFinished = false
    drawing.add(shape: shape)
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing) {
    lastVelocity = .zero
    shapeInProgress = AMPenShape()
    shapeInProgress?.start = point
  }

  public func drawContine(point: CGPoint, velocity: CGPoint, drawing: AMDrawing) {
    guard let shape = shapeInProgress else { return }
    let lastPoint = shape.segments.last?.b ?? shape.start
    let segmentWidth: CGFloat

    if velocityBasedWidth {
      segmentWidth = AMDrawingUtils.modulatedWidth(
        width: shape.width,
        velocity: velocity,
        previousVelocity: lastVelocity,
        previousWidth: shape.segments.last?.width ?? shape.width)
    } else {
      segmentWidth = shape.width
    }
    shape.add(segment: AMLineSegment(a: lastPoint, b: point, width: segmentWidth))
    lastVelocity = velocity
  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing) {
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

  public override func drawStart(point: CGPoint, drawing: AMDrawing) {
    super.drawStart(point: point, drawing: drawing)
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

