//
//  AMDrawingView.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

private func renderImage(size: CGSize, _ code: (CGContext) -> Void) -> UIImage? {
  UIGraphicsBeginImageContextWithOptions(size, false, 0)
  guard let context = UIGraphicsGetCurrentContext() else {
    UIGraphicsEndImageContext()
    return nil
  }
  code(context)
  let image = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return image
}

public class AMDrawingView: UIView {
  public var tool: AMDrawingTool?
  public var globalToolState: AMGlobalToolState {
    didSet {
      globalToolState.delegate = self
      tool?.apply(state: globalToolState)
      applySelectionViewState()
    }
  }
  public lazy var drawing: AMDrawing = { return AMDrawing(size: bounds.size, delegate: self) }()

  private var persistentBuffer: UIImage?
  private var transientBuffer: UIImage?
  private var transientBufferWithShapeInProgress: UIImage?
  private let drawingContentView = UIView()

  public let selectionIndicatorView = UIView()

  public override init(frame: CGRect) {
    globalToolState = AMGlobalToolState(
      strokeColor: .blue, fillColor: nil, strokeWidth: 20, selectedShape: nil)
    super.init(frame: frame)
    backgroundColor = .red

    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    globalToolState = AMGlobalToolState(
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
      self.transientBufferWithShapeInProgress = renderImage(size: self.drawing.size) {
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
      tool?.drawStart(point: point, drawing: drawing, state: globalToolState)
      updateUncommittedShapeBuffers()
    case .changed:
      tool?.drawContinue(point: point, velocity: sender.velocity(in: self), drawing: drawing, state: globalToolState)
      updateUncommittedShapeBuffers()
    case .ended:
      tool?.drawEnd(point: point, drawing: drawing, state: globalToolState)
      clearUncommittedShapeBuffers()
    case .failed:
      tool?.drawEnd(point: point, drawing: drawing, state: globalToolState)
      clearUncommittedShapeBuffers()
    default:
      assert(false, "State not handled")
    }
  }

  @objc private func didTap(sender: UITapGestureRecognizer) {
    tool?.drawPoint(sender.location(in: self), drawing: drawing, state: globalToolState)
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
    selectionIndicatorView.isHidden = false
  }

//  private func recreatePersistentBuffer() {
//    autoreleasepool {
//      self.persistentBuffer = renderer.image(actions: {
//        for shape in self.drawing.shapes {
//          shape.render(in: $0.cgContext)
//        }
//      })
//    }
//    reapplyLayerContents()
//  }
}

extension AMDrawingView: AMDrawingDelegate {
  public func drawingDidAddShape(_ shape: AMShape) {
    persistentBuffer = renderImage(size: drawing.size) {
      self.persistentBuffer?.draw(at: .zero)
      shape.render(in: $0)
    }
    reapplyLayerContents()
  }
}

extension AMDrawingView: AMGlobalToolStateDelegate {
  public func toolState(
    _ toolState: AMGlobalToolState,
    didSetSelectedShape selectedShape: AMShapeWithBoundingRect?)
  {
    tool?.apply(state: globalToolState)
    applySelectionViewState()
  }
}

// MARK: Models

public class AMDrawing {
  weak var delegate: AMDrawingDelegate?

  var size: CGSize
  var shapes: [AMShape] = []

  init(size: CGSize, delegate: AMDrawingDelegate? = nil) {
    self.size = size
    self.delegate = delegate
  }

  func add(shape: AMShape) {
    shapes.append(shape)
    delegate?.drawingDidAddShape(shape)
  }
}

public protocol AMDrawingDelegate: AnyObject {
  func drawingDidAddShape(_ shape: AMShape)
}

public class AMGlobalToolState {
  public var strokeColor: UIColor?
  public var fillColor: UIColor?
  public var strokeWidth: CGFloat
  public var selectedShape: AMShapeWithBoundingRect? {
    didSet {
      delegate?.toolState(self, didSetSelectedShape: selectedShape)
    }
  }

  public weak var delegate: AMGlobalToolStateDelegate?

  init(
    strokeColor: UIColor?,
    fillColor: UIColor?,
    strokeWidth: CGFloat,
    selectedShape: AMShapeWithBoundingRect?)
  {
    self.strokeColor = strokeColor
    self.fillColor = fillColor
    self.strokeWidth = strokeWidth
    self.selectedShape = selectedShape
  }
}

public protocol AMGlobalToolStateDelegate: AnyObject {
  func toolState(
    _ toolState: AMGlobalToolState,
    didSetSelectedShape selectedShape: AMShapeWithBoundingRect?)
}
