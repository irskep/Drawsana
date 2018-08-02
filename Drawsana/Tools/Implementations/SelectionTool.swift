//
//  AMDrawingTool+Text.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class SelectionTool: DrawingTool {
  public var isProgressive: Bool { return false }

  var originalTransform: ShapeTransform?
  var startPoint: CGPoint?

  public init() {

  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    var newSelection: ShapeSelectable?
    for shape in context.drawing.shapes {
      if shape.hitTest(point: point), let castShape = shape as? ShapeSelectable {
        if castShape === context.toolState.selectedShape {
          // TODO: fire a notification? need to somehow allow the text tool to
          // take over if the shape is text.
        } else {
          newSelection = castShape
        }
        break
      }
    }
    context.toolState.selectedShape = newSelection
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let selectedShape = context.toolState.selectedShape else { return }
    originalTransform = selectedShape.transform
    startPoint = point
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolState.selectedShape,
      let startPoint = startPoint else
    {
        return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.isPersistentBufferDirty = true
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolState.selectedShape,
      let startPoint = startPoint else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.isPersistentBufferDirty = true
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolState.selectedShape?.transform = originalTransform ?? .identity
    context.isPersistentBufferDirty = true
  }
}
