//
//  AMDrawingTool+Freehand.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class PenTool: DrawingTool, ToolWithShapeInProgressRendering {
  public typealias ShapeType = AMPenShape

  public var shapeInProgress: AMPenShape?

  public var isProgressive: Bool { return true }

  private var lastVelocity: CGPoint = .zero

  public var velocityBasedWidth: Bool = true

  public init() { }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    let shape = AMPenShape()
    shape.start = point
    shape.isFinished = false
    shape.apply(state: context.toolState)
    context.drawing.add(shape: shape)
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    lastVelocity = .zero
    shapeInProgress = AMPenShape()
    shapeInProgress?.start = point
    shapeInProgress?.apply(state: context.toolState)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard let shape = shapeInProgress else { return }
    let lastPoint = shape.segments.last?.b ?? shape.start
    let segmentWidth: CGFloat

    if velocityBasedWidth {
      segmentWidth = DrawsanaUtilities.modulatedWidth(
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

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress?.isFinished = true
    context.drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = nil
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.renderLatestSegment(in: transientContext)
  }
}

public class EraserTool: PenTool {
  public override init() {
    super.init()
    velocityBasedWidth = false
  }

  public override func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    super.handleDragStart(context: context, point: point)
    shapeInProgress?.isEraser = true
  }
}
