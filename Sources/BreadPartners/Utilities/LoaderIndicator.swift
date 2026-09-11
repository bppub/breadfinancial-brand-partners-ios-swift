//------------------------------------------------------------------------------
//  File:          LoaderIndicator.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

/// BallSpinFadeLoader class.
///
/// Handles the animation or behavior for a ball spin fade loader, typically used for showing loading states.
internal class LoaderIndicator: UIView {

    private let placementsConfiguration: PlacementConfiguration
    private var ballLayers: [CALayer] = []
    private let ballCount = 8  // Number of balls
    private let radius: CGFloat = 30.0  // Radius of the circular path for balls
    private let ballSize: CGFloat = 20.0  // Size of each ball

    init(frame: CGRect, placementsConfiguration: PlacementConfiguration) {
        self.placementsConfiguration = placementsConfiguration
        super.init(frame: frame)
        setupLoader()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLoader() {
        let angleStep = 2 * CGFloat.pi / CGFloat(ballCount)
        let beginTimes: [CFTimeInterval] = [0, 0.12, 0.24, 0.36, 0.48, 0.6, 0.72, 0.84]

        for i in 0..<ballCount {
            let ballLayer = createBallLayer(atIndex: i, angleStep: angleStep, beginTime: beginTimes[i])
            layer.addSublayer(ballLayer)
            ballLayers.append(ballLayer)
        }

        startAnimation()
    }

    private func createBallLayer(atIndex index: Int, angleStep: CGFloat, beginTime: CFTimeInterval) -> CALayer {
        let angle = angleStep * CGFloat(index)
        let ballLayer = CALayer()
        ballLayer.bounds = CGRect(x: 0, y: 0, width: ballSize, height: ballSize)
        ballLayer.cornerRadius = ballSize / 2
        ballLayer.backgroundColor = placementsConfiguration.popUpStyling?.loaderColor.cgColor
        ballLayer.opacity = 0.0

        // Calculate ball position
        let x = bounds.midX + radius * cos(angle)
        let y = bounds.midY + radius * sin(angle)
        ballLayer.position = CGPoint(x: x, y: y)

        // Create the fade-in/out and scale animation
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

        return ballLayer
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
        for ballLayer in ballLayers {
            ballLayer.isHidden = false
        }
        startAnimation()
    }

    func stopAnimating() {
        for ballLayer in ballLayers {
            ballLayer.isHidden = true
            ballLayer.removeAllAnimations()
        }
    }
}
