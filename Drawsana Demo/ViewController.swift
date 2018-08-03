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
    TextTool(),
    SelectionTool(),
    EllipseTool(),
    PenTool(),
    EraserTool(),
    LineTool(),
    RectTool(),
  ]
  var toolIndex = 0

  override func loadView() {
    self.view = UIView()

    toolButton.translatesAutoresizingMaskIntoConstraints = false
    toolButton.setTitle("No Tool", for: .normal)
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
    drawingView.delegate = self

    drawingView.set(tool: tools[toolIndex])
  }

  @objc private func changeTool(_ sender: Any?) {
    toolIndex = (toolIndex + 1) % tools.count
    drawingView.set(tool: tools[toolIndex])
    toolButton.setTitle(tools[toolIndex].name, for: .normal)
  }
}

extension ViewController: DrawsanaViewDelegate {
  func drawsanaViewAssociatedTool(for shape: Shape) -> DrawingTool? {
    if shape as? RectShape != nil {
      return tools[5]
    }
    return nil
  }

  func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool?) {
    toolButton.setTitle(tool?.name, for: .normal)
  }
}
