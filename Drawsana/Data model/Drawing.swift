//
//  Drawing.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class Drawing {
  weak var delegate: DrawingDelegate?

  var size: CGSize
  var shapes: [Shape] = []

  init(size: CGSize, delegate: DrawingDelegate? = nil) {
    self.size = size
    self.delegate = delegate
  }

  func add(shape: Shape) {
    shapes.append(shape)
    delegate?.drawingDidAddShape(shape)
  }
}

public protocol DrawingDelegate: AnyObject {
  func drawingDidAddShape(_ shape: Shape)
}
