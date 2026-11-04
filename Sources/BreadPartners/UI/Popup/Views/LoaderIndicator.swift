//------------------------------------------------------------------------------
//  File:          LoaderIndicator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import UIKit

/// BallSpinFadeLoader class.
///
/// Handles the animation or behavior for a ball spin fade loader, typically used for showing loading states.
internal class LoaderIndicator: UIView {

    private let color: UIColor
    private var ballLayers: [CALayer] = []
    private let ballCount = 8  // Number of balls
    private let radius: CGFloat = 30.0  // Radius of the circular path for balls
    private let ballSize: CGFloat = 20.0  // Size of each ball
    private let animationBeginTimes: [CFTimeInterval] = [0, 0.12, 0.24, 0.36, 0.48, 0.6, 0.72, 0.84]

    init(frame: CGRect, color: UIColor) {
        self.color = color
        super.init(frame: frame)
        setupLoader()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLoader() {
        let angleStep = 2 * CGFloat.pi / CGFloat(ballCount)

        for i in 0..<ballCount {
            let ballLayer = createBallLayer(atIndex: i, angleStep: angleStep)
            layer.addSublayer(ballLayer)
            ballLayers.append(ballLayer)
            addBallAnimation(to: ballLayer, beginTime: animationBeginTimes[i])
        }

        startAnimation()
    }

    private func createBallLayer(atIndex index: Int, angleStep: CGFloat) -> CALayer {
        let angle = angleStep * CGFloat(index)
        let ballLayer = CALayer()
        ballLayer.bounds = CGRect(x: 0, y: 0, width: ballSize, height: ballSize)
        ballLayer.cornerRadius = ballSize / 2
        ballLayer.backgroundColor = color.cgColor
        ballLayer.opacity = 0.0

        // Calculate ball position
        let x = bounds.midX + radius * cos(angle)
        let y = bounds.midY + radius * sin(angle)
        ballLayer.position = CGPoint(x: x, y: y)

        return ballLayer
    }

    private func addBallAnimation(to ballLayer: CALayer, beginTime: CFTimeInterval) {
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.keyTimes = [0, 0.5, 1]
        scaleAnimation.values = [1, 0.5, 0]
        scaleAnimation.duration = 1.0

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.keyTimes = [0, 0.5, 1]
        opacityAnimation.values = [1, 0.5, 0]
        opacityAnimation.duration = 1.0

        // Combine the animations into a group
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)
        animationGroup.duration = 1.0
        animationGroup.repeatCount = .infinity
        animationGroup.beginTime = CACurrentMediaTime() + beginTime

        // Add animation to ball layer
        ballLayer.add(animationGroup, forKey: "ballAnimation")
    }

    private func startAnimation() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.toValue = 2 * CGFloat.pi
        rotateAnimation.duration = 5.0
        rotateAnimation.repeatCount = .infinity
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(rotateAnimation, forKey: "rotation")
    }

    func startAnimating() {
        for (index, ballLayer) in ballLayers.enumerated() {
            ballLayer.isHidden = false
            if ballLayer.animation(forKey: "ballAnimation") == nil {
                addBallAnimation(to: ballLayer, beginTime: animationBeginTimes[index])
            }
        }
        startAnimation()
    }

    func stopAnimating() {
        for ballLayer in ballLayers {
            ballLayer.isHidden = true
            ballLayer.removeAnimation(forKey: "ballAnimation")
        }
        layer.removeAnimation(forKey: "rotation")
    }
}
