//
//  AMShape.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

// MARK: Protocols

public protocol AMShape: AnyObject {
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

public protocol AMShapeWithTwoPoints {
  var a: CGPoint { get set }
  var b: CGPoint { get set }

  var strokeWidth: CGFloat { get set }
}

extension AMShapeWithTwoPoints {
  public var rect: CGRect {
    let x1 = min(a.x, b.x)
    let y1 = min(a.y, b.y)
    let x2 = max(a.x, b.x)
    let y2 = max(a.y, b.y)
    return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
  }

  public var boundingRect: CGRect {
    return rect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}

// MARK: Shapes

public class AMLineShape: AMShapeWithBoundingRect, AMShapeWithTwoPoints {
  public var isSelectable: Bool { return false }

  public var a: CGPoint = .zero
  public var b: CGPoint = .zero
  public var color: UIColor = .black
  public var strokeWidth: CGFloat = 10
  public var capStyle: CGLineCap = .round
  public var joinStyle: CGLineJoin = .round
  public var dashPhase: CGFloat?
  public var dashLengths: [CGFloat]?

  public init() {

  }

  public func render(in context: CGContext) {
    context.setLineCap(capStyle)
    context.setLineJoin(joinStyle)
    context.setLineWidth(strokeWidth)
    context.setStrokeColor(color.cgColor)
    if let dashPhase = dashPhase, let dashLengths = dashLengths {
      context.setLineDash(phase: dashPhase, lengths: dashLengths)
    } else {
      context.setLineDash(phase: 0, lengths: [])
    }
    context.move(to: a)
    context.addLine(to: b)
    context.strokePath()
  }
}

public class AMRectShape: AMShapeWithBoundingRect, AMShapeWithTwoPoints {
  public var isSelectable: Bool { return true }

  public var a: CGPoint = .zero
  public var b: CGPoint = .zero
  public var strokeColor: UIColor = .black
  public var fillColor: UIColor = .clear
  public var strokeWidth: CGFloat = 10
  public var capStyle: CGLineCap = .round
  public var joinStyle: CGLineJoin = .round
  public var dashPhase: CGFloat?
  public var dashLengths: [CGFloat]?

  public init() {

  }

  public func render(in context: CGContext) {
    context.setLineCap(capStyle)
    context.setLineJoin(joinStyle)
    context.setLineWidth(strokeWidth)
    context.setStrokeColor(strokeColor.cgColor)
    if let dashPhase = dashPhase, let dashLengths = dashLengths {
      context.setLineDash(phase: dashPhase, lengths: dashLengths)
    } else {
      context.setLineDash(phase: 0, lengths: [])
    }
    context.addRect(rect)
    context.strokePath()

    context.setFillColor(fillColor.cgColor)
    context.addRect(rect)
    context.fillPath()
  }
}

public class AMEllipseShape: AMShapeWithBoundingRect, AMShapeWithTwoPoints {
  public var isSelectable: Bool { return true }

  public var a: CGPoint = .zero
  public var b: CGPoint = .zero
  public var strokeColor: UIColor = .black
  public var fillColor: UIColor = .clear
  public var strokeWidth: CGFloat = 10
  public var capStyle: CGLineCap = .round
  public var joinStyle: CGLineJoin = .round
  public var dashPhase: CGFloat?
  public var dashLengths: [CGFloat]?

  public init() {

  }

  public func render(in context: CGContext) {
    context.setLineCap(capStyle)
    context.setLineJoin(joinStyle)
    context.setLineWidth(strokeWidth)
    context.setStrokeColor(strokeColor.cgColor)
    if let dashPhase = dashPhase, let dashLengths = dashLengths {
      context.setLineDash(phase: dashPhase, lengths: dashLengths)
    } else {
      context.setLineDash(phase: 0, lengths: [])
    }

    context.addEllipse(in: rect)
    context.strokePath()

    context.setFillColor(fillColor.cgColor)
    context.addEllipse(in: rect)
    context.fillPath()
  }
}

public struct AMLineSegment {
  var a: CGPoint
  var b: CGPoint
  var width: CGFloat

  var midPoint: CGPoint {
    return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
  }
}

public class AMPenShape: AMShape {
  public var isFinished = true
  public var color: UIColor = .black
  public var start: CGPoint = .zero
  public var strokeWidth: CGFloat = 10
  public var segments: [AMLineSegment] = []
  public var isEraser: Bool = false

  public var isSelectable: Bool { return false }
  public func hitTest(point: CGPoint) -> Bool {
    return false
  }

  public func add(segment: AMLineSegment) {
    segments.append(segment)
  }

  private func render(in context: CGContext, onlyLast: Bool = false) {
    guard !segments.isEmpty else {
      if !isFinished {
        // Draw a dot
        context.setFillColor(color.cgColor)
        context.addArc(center: start, radius: strokeWidth / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        context.fillPath()
      } else {
        // draw nothing; user will keep drawing
      }
      return
    }

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color.cgColor)
    if isEraser {
      context.setBlendMode(.clear)
    }

    var lastSegment: AMLineSegment?
    if onlyLast, segments.count > 1 {
      lastSegment = segments[segments.count - 2]
    }
    for segment in (onlyLast ? [segments.last!] : segments) {
      context.setLineWidth(segment.width)
      if let previousMid = lastSegment?.midPoint {
        let currentMid = segment.midPoint
        context.move(to: previousMid)
        context.addQuadCurve(to: currentMid, control: segment.a)
        context.strokePath()
      } else {
        context.move(to: segment.a)
        context.addLine(to: segment.b)
        context.strokePath()
      }
      lastSegment = segment
    }
  }

  public func render(in context: CGContext) {
    render(in: context, onlyLast: false)
  }

  public func renderLatestSegment(in context: CGContext) {
    render(in: context, onlyLast: true)
  }
}
