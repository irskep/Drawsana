//
//  AMDrawingView.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class DrawsanaView: UIView {
  public var tool: DrawingTool?
  public var globalToolState: GlobalToolState {
    didSet {
      globalToolState.delegate = self
      tool?.apply(state: globalToolState)
      applySelectionViewState()
    }
  }
  public lazy var drawing: Drawing = { return Drawing(size: bounds.size, delegate: self) }()

  private var persistentBuffer: UIImage?
  private var transientBuffer: UIImage?
  private var transientBufferWithShapeInProgress: UIImage?
  private let drawingContentView = UIView()

  public let selectionIndicatorView = UIView()

  public override init(frame: CGRect) {
    globalToolState = GlobalToolState(
      strokeColor: .blue, fillColor: nil, strokeWidth: 20, selectedShape: nil)
    super.init(frame: frame)
    backgroundColor = .red

    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    globalToolState = GlobalToolState(
      strokeColor: .blue, fillColor: nil, strokeWidth: 20, selectedShape: nil)
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    globalToolState.delegate = self
    isUserInteractionEnabled = true
    layer.actions = [
      "contents": NSNull(),
    ]
    selectionIndicatorView.layer.actions = [
      "transform": NSNull(),
    ]

    addSubview(drawingContentView)
    addSubview(selectionIndicatorView)

    drawingContentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      drawingContentView.leftAnchor.constraint(equalTo: leftAnchor),
      drawingContentView.rightAnchor.constraint(equalTo: rightAnchor),
      drawingContentView.topAnchor.constraint(equalTo: topAnchor),
      drawingContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = true
    selectionIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    // TODO: allow config
    selectionIndicatorView.layer.borderColor = UIColor.blue.cgColor
    selectionIndicatorView.layer.borderWidth = 1
    selectionIndicatorView.isHidden = true

    addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(sender:))))
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(sender:))))
  }

  // MARK: Gesture recognizers

  @objc private func didPan(sender: UIPanGestureRecognizer) {
    autoreleasepool { _didPan(sender: sender) }
  }

  private func _didPan(sender: UIPanGestureRecognizer) {
    let updateUncommittedShapeBuffers: () -> Void = {
      self.transientBufferWithShapeInProgress = DrawsanaUtilities.renderImage(size: self.drawing.size) {
        self.transientBuffer?.draw(at: .zero)
        self.tool?.renderShapeInProgress(transientContext: $0)
      }
      self.drawingContentView.layer.contents = self.transientBufferWithShapeInProgress?.cgImage
      if self.tool?.isProgressive == true {
        self.transientBuffer = self.transientBufferWithShapeInProgress
      }
    }

    let clearUncommittedShapeBuffers: () -> Void = {
      self.reapplyLayerContents()
    }

    let point = sender.location(in: self)
    let context = ToolOperationContext(drawing: drawing, toolState: globalToolState, isPersistentBufferDirty: false)
    switch sender.state {
    case .began:
      if let persistentBuffer = persistentBuffer, let cgImage = persistentBuffer.cgImage {
        transientBuffer = UIImage(
          cgImage: cgImage,
          scale: persistentBuffer.scale,
          orientation: persistentBuffer.imageOrientation)
      } else {
        transientBuffer = nil
      }
      tool?.handleDragStart(context: context, point: point)
      updateUncommittedShapeBuffers()
    case .changed:
      tool?.handleDragContinue(context: context, point: point, velocity: sender.velocity(in: self))
      updateUncommittedShapeBuffers()
    case .ended:
      tool?.handleDragEnd(context: context, point: point)
      clearUncommittedShapeBuffers()
    case .failed:
      tool?.handleDragCancel(context: context, point: point)
      clearUncommittedShapeBuffers()
    default:
      assert(false, "State not handled")
    }

    if context.isPersistentBufferDirty {
      redrawAbsolutelyEverything()
      applySelectionViewState()
    }
  }

  @objc private func didTap(sender: UITapGestureRecognizer) {
    let context = ToolOperationContext(drawing: drawing, toolState: globalToolState, isPersistentBufferDirty: false)
    tool?.handleTap(context: context, point: sender.location(in: self))
  }

  // MARK: Making stuff show up

  private func reapplyLayerContents() {
    self.drawingContentView.layer.contents = persistentBuffer?.cgImage
  }

  private func applySelectionViewState() {
    guard let shape = globalToolState.selectedShape else {
      selectionIndicatorView.isHidden = true
      return
    }
    // TODO: allow inset config
    selectionIndicatorView.frame = shape.boundingRect.insetBy(dx: -4, dy: -4)
    selectionIndicatorView.transform = selectionIndicatorView.transform.concatenating(shape.transform.affineTransform)
    selectionIndicatorView.isHidden = false
  }

  private func redrawAbsolutelyEverything() {
    autoreleasepool {
      self.persistentBuffer = DrawsanaUtilities.renderImage(size: drawing.size) {
        for shape in self.drawing.shapes {
          shape.render(in: $0)
        }
      }
    }
    reapplyLayerContents()
  }
}

extension DrawsanaView: DrawingDelegate {
  public func drawingDidAddShape(_ shape: Shape) {
    persistentBuffer = DrawsanaUtilities.renderImage(size: drawing.size) {
      self.persistentBuffer?.draw(at: .zero)
      shape.render(in: $0)
    }
    reapplyLayerContents()
  }
}

extension DrawsanaView: GlobalToolStateDelegate {
  public func toolState(
    _ toolState: GlobalToolState,
    didSetSelectedShape selectedShape: ShapeSelectable?)
  {
    tool?.apply(state: globalToolState)
    applySelectionViewState()
  }
}
