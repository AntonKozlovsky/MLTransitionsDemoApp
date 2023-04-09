import UIKit
import Combine

protocol ImageSeriesAnimator {
    
    func animate(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) -> AnyPublisher<Bool, Never>
}
