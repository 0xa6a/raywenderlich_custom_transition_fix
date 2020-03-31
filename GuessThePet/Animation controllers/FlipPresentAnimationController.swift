/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class FlipPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
  
  private let originFrame: CGRect
  
  init(originFrame: CGRect) {
    self.originFrame = originFrame
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.6
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    // 1 Extract a reference to both the view controller being replaced and the one being presented. Make a snapshot of what the screen will look like after the transition.
    guard let fromVC = transitionContext.viewController(forKey: .from),
      let toVC = transitionContext.viewController(forKey: .to),
      let snapshot = toVC.view.snapshotView(afterScreenUpdates: true)
      else {
        return
    }
    
    // 2 UIKit encapsulates the entire transition inside a container view to simplify managing both the view hierarchy and the animations. Get a reference to the container view and determine what the final frame of the new view will be.
    let containerView = transitionContext.containerView
    let finalFrame = transitionContext.finalFrame(for: toVC)
    
    // 3 Configure the snapshot’s frame and drawing so that it exactly matches and covers the card in the “from” view.
    snapshot.frame = originFrame
    snapshot.layer.cornerRadius = CardViewController.cardCornerRadius
    snapshot.layer.masksToBounds = true
    
    // 4 Add the new “to” view to the view hierarchy and hide it. Place the snapshot in front of it.
    containerView.addSubview(toVC.view)
    containerView.addSubview(snapshot)
    toVC.view.isHidden = true
    
    // 5 Set up the beginning state of the animation by rotating the snapshot 90˚ around its y-axis. This causes it to be edge-on to the viewer and, therefore, not visible when the animation begins.
    AnimationHelper.perspectiveTransform(for: containerView)
    snapshot.layer.transform = AnimationHelper.yRotation(.pi / 2)
    // 6 Get the duration of the animation.
    let duration = transitionDuration(using: transitionContext)
    
    // 1 You use a standard UIView keyframe animation. The duration of the animation must exactly match the length of the transition.
    UIView.animateKeyframes(
      withDuration: duration,
      delay: 0,
      options: .calculationModeCubic,
      animations: {
        // 2 Start by rotating the “from” view 90˚ around its y-axis to hide it from view.
        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1/3) {
          fromVC.view.layer.transform = AnimationHelper.yRotation(-.pi / 2)
        }
        
        // 3 Next, reveal the snapshot by rotating it back from its edge-on state that you set up above.
        UIView.addKeyframe(withRelativeStartTime: 1/3, relativeDuration: 1/3) {
          snapshot.layer.transform = AnimationHelper.yRotation(0.0)
        }
        
        // 4 Set the frame of the snapshot to fill the screen.
        UIView.addKeyframe(withRelativeStartTime: 2/3, relativeDuration: 1/3) {
          snapshot.frame = finalFrame
          snapshot.layer.cornerRadius = 0
        }
    },
      // 5 The snapshot now exactly matches the “to” view so it’s finally safe to reveal the real “to” view. Remove the snapshot from the view hierarchy since it’s no longer needed. Next, restore the “from” view to its original state; otherwise, it would be hidden when transitioning back. Calling completeTransition(_:) informs UIKit that the animation is complete. It will ensure the final state is consistent and remove the “from” view from the container.
      completion: { _ in
        toVC.view.isHidden = false
        snapshot.removeFromSuperview()
        fromVC.view.layer.transform = CATransform3DIdentity
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    })
  }
}
