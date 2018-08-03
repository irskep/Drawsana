//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

/*
 Text tool behavior spec:

 # Activate tool without shape, then tap:

 Add text under finger, or at point determined by delegate

 # Activate tool with shape:

 Begin editing shape immediately

 # Tap on text

 */

public protocol TextToolDelegate: AnyObject {
  func textToolPointForNewText(tappedPoint: CGPoint) -> CGPoint
  func textToolDidTapAway(tappedPoint: CGPoint)
}

public class TextTool: NSObject, DrawingTool, UITextViewDelegate {
  public let isProgressive = false
  public let name: String = "Text"
  public weak var delegate: TextToolDelegate?

  public var shapeInProgress: TextShape?

  var originalTransform: ShapeTransform?
  var startPoint: CGPoint?

  public init(delegate: TextToolDelegate? = nil) {
    self.delegate = delegate
    super.init()
  }

  public func deactivate(context: ToolOperationContext) {
    context.interactiveView?.resignFirstResponder()
    context.interactiveView = nil
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let shapeInProgress = shapeInProgress {
      if shapeInProgress.hitTest(point: point) {
        // TODO: forward tap to text view
      } else {
        // TODO: save changes
        self.shapeInProgress = nil
        context.toolState.selectedShape = nil
        context.interactiveView?.resignFirstResponder()
        context.interactiveView = nil
        delegate?.textToolDidTapAway(tappedPoint: point)
      }
      return
    }

    shapeInProgress = TextShape()
    shapeInProgress!.transform.translation = delegate?.textToolPointForNewText(tappedPoint: point) ?? point
    context.interactiveView = shapeInProgress?.textView
    context.toolState.selectedShape = shapeInProgress
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
    shapeInProgress!.textView.delegate = self
    shapeInProgress!.textView.becomeFirstResponder()
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress, shapeInProgress.hitTest(point: point) else { return }
    originalTransform = shapeInProgress.transform
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
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
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
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolState.selectedShape?.transform = originalTransform ?? .identity
    context.isPersistentBufferDirty = true
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
  }

  public func textViewDidChange(_ textView: UITextView) {
    shapeInProgress!.text = textView.text ?? ""
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
  }
}
