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

  func handleTap(context: ToolOperationContext, point: CGPoint)
  func handleDragStart(context: ToolOperationContext, point: CGPoint)
  func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint)
  func handleDragEnd(context: ToolOperationContext, point: CGPoint)
  func handleDragCancel(context: ToolOperationContext, point: CGPoint)

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

