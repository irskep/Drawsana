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
  var isPersistentBufferDirty = false

  init(drawing: Drawing, toolState: GlobalToolState, isPersistentBufferDirty: Bool) {
    self.drawing = drawing
    self.toolState = toolState
    self.isPersistentBufferDirty = isPersistentBufferDirty
  }
}
