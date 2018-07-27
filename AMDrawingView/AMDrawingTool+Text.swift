//
//  AMDrawingTool+Text.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class AMSelectionTool: AMDrawingTool {
  public var isProgressive: Bool { return false }

  public init() {

  }

  public func drawPoint(_ point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {
    var newSelection: AMSelectableShape?
    for shape in drawing.shapes {
      if shape.hitTest(point: point), let castShape = shape as? AMSelectableShape, castShape !== state.selectedShape {
        newSelection = castShape
        break
      }
    }
    state.selectedShape = newSelection
  }

  public func drawStart(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {

  }

  public func drawContinue(point: CGPoint, velocity: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {

  }

  public func drawEnd(point: CGPoint, drawing: AMDrawing, state: AMGlobalToolState) {

  }
}
