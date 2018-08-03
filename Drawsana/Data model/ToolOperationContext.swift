//
//  ToolOperationContext.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class ToolOperationContext {
  let drawing: Drawing
  let toolState: GlobalToolState
  var interactiveView: UIView?
  var isPersistentBufferDirty: Bool
  var shapeForAssociatedTool: Shape?

  init(
    drawing: Drawing,
    toolState: GlobalToolState,
    interactiveView: UIView?,
    isPersistentBufferDirty: Bool = false,
    shapeForAssociatedTool: Shape? = nil)
  {
    self.drawing = drawing
    self.toolState = toolState
    self.interactiveView = interactiveView
    self.isPersistentBufferDirty = isPersistentBufferDirty
    self.shapeForAssociatedTool = shapeForAssociatedTool
  }
}
