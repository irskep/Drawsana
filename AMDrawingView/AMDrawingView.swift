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
  public lazy var drawing: AMDrawing = { return AMDrawing(size: bounds.size, delegate: self) }()

  private var persistentBuffer: UIImage?
  private var transientBuffer: UIImage?
  private var transientBufferWithShapeInProgress: UIImage?
  private let drawingContentView = UIView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .red

    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    isUserInteractionEnabled = true
    layer.actions = [
      "contents": NSNull(),
    ]
    addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(sender:))))
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(sender:))))

    drawingContentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(drawingContentView)
    NSLayoutConstraint.activate([
      drawingContentView.leftAnchor.constraint(equalTo: leftAnchor),
      drawingContentView.rightAnchor.constraint(equalTo: rightAnchor),
      drawingContentView.topAnchor.constraint(equalTo: topAnchor),
      drawingContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
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
      tool?.drawStart(point: point, drawing: drawing)
      updateUncommittedShapeBuffers()
    case .changed:
      tool?.drawContine(point: point, velocity: sender.velocity(in: self), drawing: drawing)
      updateUncommittedShapeBuffers()
    case .ended:
      tool?.drawEnd(point: point, drawing: drawing)
      clearUncommittedShapeBuffers()
    case .failed:
      tool?.drawEnd(point: point, drawing: drawing)
      clearUncommittedShapeBuffers()
    default:
      assert(false, "State not handled")
    }
  }

  @objc private func didTap(sender: UITapGestureRecognizer) {
    tool?.drawPoint(sender.location(in: self), drawing: drawing)
  }

  // MARK: Making stuff show up

  private func reapplyLayerContents() {
    self.drawingContentView.layer.contents = persistentBuffer?.cgImage
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

// MARK: Shape protocols

public protocol AMShape {
  var isSelectable: Bool { get }
  func render(in context: CGContext)
  func hitTest(point: CGPoint) -> Bool
}
public protocol AMShapeWithBoundingRect: AMShape {
  var boundingRect: CGRect { get }
}
extension AMShapeWithBoundingRect {
  public func hitTest(point: CGPoint) -> Bool {
    return boundingRect.contains(point)
  }
}

// MARK: Tool protocols

public protocol AMDrawingTool {
  var isProgressive: Bool { get }

  func activate()
  func deactivate()

  func drawPoint(_ point: CGPoint, drawing: AMDrawing)
  func drawStart(point: CGPoint, drawing: AMDrawing)
  func drawContine(point: CGPoint, velocity: CGPoint, drawing: AMDrawing)
  func drawEnd(point: CGPoint, drawing: AMDrawing)

  func renderShapeInProgress(transientContext: CGContext)
}
public extension AMDrawingTool {
  func renderShapeInProgress(transientContext: CGContext) { }
}

public protocol AMDrawingToolWithShapeInProgress: AMDrawingTool {
  associatedtype ShapeType: AMShape
  var shapeInProgress: ShapeType? { get }
}
extension AMDrawingToolWithShapeInProgress {
  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
}

