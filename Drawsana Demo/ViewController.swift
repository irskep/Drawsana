//
//  ViewController.swift
//  AMDrawingView Demo
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit
import Drawsana

class ViewController: UIViewController {
  lazy var drawingView: DrawsanaView = { return DrawsanaView() }()
  let toolButton = UIButton(type: .custom)

  let tools: [DrawingTool] = [
    EllipseTool(),
    SelectionTool(),
    PenTool(),
    EraserTool(),
    LineTool(),
    RectTool(),
  ]
  let toolNames: [String] = [
    "Ellipse",
    "Select",
    "Pen",
    "Eraser",
    "Line",
    "Rect",
  ]
  var toolIndex = 0

  override func loadView() {
    self.view = UIView()

    toolButton.translatesAutoresizingMaskIntoConstraints = false
    toolButton.setTitle(toolNames[0], for: .normal)
    toolButton.addTarget(self, action: #selector(changeTool(_:)), for: .touchUpInside)
    toolButton.setContentHuggingPriority(.required, for: .vertical)
    view.addSubview(toolButton)

    drawingView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(drawingView)
    NSLayoutConstraint.activate([
      drawingView.leftAnchor.constraint(equalTo: view.leftAnchor),
      drawingView.rightAnchor.constraint(equalTo: view.rightAnchor),
      drawingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

      toolButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      toolButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      drawingView.bottomAnchor.constraint(equalTo: toolButton.topAnchor),
    ])

  }

  override func viewDidLoad() {
    super.viewDidLoad()

    drawingView.tool = tools[toolIndex]
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @objc private func changeTool(_ sender: Any?) {
    toolIndex = (toolIndex + 1) % tools.count
    drawingView.tool = tools[toolIndex]
    toolButton.setTitle(toolNames[toolIndex], for: .normal)
  }
}

