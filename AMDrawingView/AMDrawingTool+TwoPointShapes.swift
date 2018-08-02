//
//  AMDrawingTool+TwoPointShapes.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/// Convenience superclass: create and update shapeInProgress by dragging from point A to point B
public class AMDrawingToolForShapeWithTwoPoints: AMDrawingTool {
  public typealias ShapeType = AMShape & AMShapeWithTwoPoints & AMToolStateAppliable

  public var shapeInProgress: ShapeType?

  func makeShape() -> ShapeType {
    fatalError("Override me")
  }

  public var isProgressive: Bool { return false }

  public init() { }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    var shape = makeShape()
    shape.a = point
    shape.b = point
    shape.apply(state: context.toolState)
    context.drawing.add(shape: shape)
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = makeShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
    shapeInProgress?.apply(state: context.toolState)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    shapeInProgress?.b = point
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress?.b = point
    context.drawing.add(shape: shapeInProgress!)
    shapeInProgress = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = nil
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
}

public class AMLineTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMLineShape() }
}

public class AMRectTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMRectShape() }
}

public class AMEllipseTool: AMDrawingToolForShapeWithTwoPoints {
  public override func makeShape() -> ShapeType { return AMEllipseShape() }
}
